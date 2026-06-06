(*
Nordson ProPlus4 8-Tag Syringe Printer Controller
Allen-Bradley Micro 820 - Structured Text

Implements custom multiplexed binary protocol over 8 digital I/O channels:
- 3-bit tag position (0-7) for 4x2 fixture grid
- 4-bit bit index (1-10) for sparse circle selection per tag (0 = complete)
- Run pulse trigger + rising-edge handshake for sequencing
- Supports web-driven batching (8-tag windows from 2000-tag jobs)
- Printed status tracking for resume / skip
- Integrated laser/UV mode and completion signaling

Channel mapping:
  DO00-03 : Bit1-4 (bit index binary)
  DO04-06 : PositionBit0-2 (tag position binary)
  P1DO00  : RunPulse (500 ms)
  DI04    : ReadyForNextBit (from Nordson Ch1 signal)
  DI01    : PrinterRunning status

Timing:
  RunPulse: 500 ms
  Post-pulse settle: 2 s

Author: Sam Snyder
*)

(* VAR declarations (excerpt for reference; full tags configured in project) *)
(*
VAR
    (* Job data - 8-tag window *)
    TagList: ARRAY[0..7] OF INT;
    NumTags: DINT;
    EightIndex: DINT;
    Web_TagList: ARRAY[0..1999] OF INT;
    Web_PrintedStatus: ARRAY[0..1999] OF INT;
    Web_NumTags: DINT;
    Web_EightIndex: DINT;
    Web_UpdateFlag: BOOL;
    Web_Reset: BOOL;

    (* Processing state - bitwise masks *)
    CurrentTagMask: INT;
    ProcessedMask: INT;
    TagIndex: INT;
    TagPosition: DINT;
    TagNumber: INT;
    BitIndex: INT;
    Channel: INT;

    (* Outputs *)
    Bit1: BOOL;
    Bit2: BOOL;
    Bit3: BOOL;
    Bit4: BOOL;
    PositionBit0: BOOL;
    PositionBit1: BOOL;
    PositionBit2: BOOL;
    RunPulse: BOOL;
    TagDoneBuzzer: BOOL;
    EightDoneBuzzer: BOOL;
    LaserPower: BOOL;

    (* Inputs *)
    PowerOn: BOOL;
    PrinterRunning: BOOL;
    StartBtn: BOOL;
    ResetBtn: BOOL;
    ReadyForNextBit: BOOL;
    Web_StartBtn: BOOL;
    LaserMode: BOOL;

    (* State machines *)
    TagState: INT;   (* 0=Idle, 1=Pulse+Delay, 2=WaitReady *)
    SetState: INT;   (* 0=Idle, 1=Processing, 2=Complete *)

    (* Timers and edges *)
    PulseTimer: TON;
    Delay: TON;
    RunDelay: TON;
    LastStartBtn: BOOL;
    StartBtnRisingEdge: BOOL;
    LastWebStartBtn: BOOL;
    WebStartBtnRisingEdge: BOOL;
    LastReadyForNextBit: BOOL;
    ReadyForNextBitRisingEdge: BOOL;

    (* Flags *)
    StartupFlag: BOOL;
    Web_InitComplete: BOOL;
    AllBitsProcessed: BOOL;
    AllTagsProcessed: BOOL;
    Started: BOOL;
    TagDoneProcessed: BOOL;
    AutoAdvance: BOOL;
    IndexOutOfBounds: BOOL;

    (* Diag *)
    Hello: INT;
    Web_TagPosition: DINT;
    Web_TagIndex: INT;

    i: INT;
END_VAR
*)

(* ==================== WEB SYNC ==================== *)
IF Web_UpdateFlag THEN
    FOR i := 0 TO 7 DO
        TagList[i] := Web_TagList[i + EightIndex];
    END_FOR;
    NumTags := MIN(Web_NumTags, 8);
    IF NumTags < 0 THEN NumTags := 0; END_IF;

    IF Web_Reset THEN
        Web_InitComplete := FALSE;
        Web_Reset := FALSE;
    END_IF;

    Web_UpdateFlag := FALSE;
END_IF;

(* ==================== I/O MAPPING ==================== *)
PowerOn := _IO_EM_DI_00;
PrinterRunning := _IO_EM_DI_01;
StartBtn := _IO_EM_DI_02;
ResetBtn := _IO_EM_DI_03;
ReadyForNextBit := _IO_EM_DI_04;
Web_StartBtn := _IO_EM_DI_05;
LaserMode := _IO_EM_DI_11;

_IO_EM_DO_00 := Bit1;
_IO_EM_DO_01 := Bit2;
_IO_EM_DO_02 := Bit3;
_IO_EM_DO_03 := Bit4;
_IO_EM_DO_04 := PositionBit0;
_IO_EM_DO_05 := PositionBit1;
_IO_EM_DO_06 := PositionBit2;

_IO_P1_DO_00 := RunPulse;
_IO_P1_DO_01 := TagDoneBuzzer;
_IO_P1_DO_02 := EightDoneBuzzer;
_IO_P1_DO_03 := LaserPower;

IF StartupFlag THEN
    RunPulse := FALSE;
    LaserPower := FALSE;
END_IF;

(* ==================== INITIALIZATION ==================== *)
IF NOT Web_InitComplete THEN
    FOR i := 0 TO 7 DO
        TagList[i] := 0;
    END_FOR;

    FOR i := 0 TO 1999 DO
        Web_PrintedStatus[i] := 0;
        Web_TagList[i] := 0;
    END_FOR;

    EightIndex := 0;
    Web_EightIndex := 0;
    NumTags := 0;
    TagIndex := 0;
    TagPosition := 0;
    TagState := 0;
    SetState := 0;

    CurrentTagMask := 0;
    ProcessedMask := 0;
    TagNumber := 0;

    RunPulse := FALSE;
    LaserPower := FALSE;
    TagDoneBuzzer := FALSE;
    TagDoneProcessed := FALSE;
    Bit1 := FALSE;
    Bit2 := FALSE;
    Bit3 := FALSE;
    Bit4 := FALSE;
    PositionBit0 := FALSE;
    PositionBit1 := FALSE;
    PositionBit2 := FALSE;

    StartupFlag := FALSE;
    Started := FALSE;
    AllBitsProcessed := FALSE;
    AllTagsProcessed := FALSE;
    Web_InitComplete := TRUE;

    LastReadyForNextBit := FALSE;
    ReadyForNextBitRisingEdge := FALSE;
    LastWebStartBtn := FALSE;
    WebStartBtnRisingEdge := FALSE;
    LastStartBtn := FALSE;
    StartBtnRisingEdge := FALSE;

    Hello := 0;
END_IF;

(* ==================== STARTUP STABILITY ==================== *)
IF NOT StartupFlag THEN
    TagState := 0;
    SetState := 0;
    RunPulse := FALSE;
    LaserPower := FALSE;
    IF Web_InitComplete THEN
        StartupFlag := TRUE;
    END_IF;
END_IF;

(* ==================== EDGE DETECTION ==================== *)
ReadyForNextBitRisingEdge := ReadyForNextBit AND NOT LastReadyForNextBit;
LastReadyForNextBit := ReadyForNextBit;

StartBtnRisingEdge := StartBtn AND NOT LastStartBtn;
LastStartBtn := StartBtn;

WebStartBtnRisingEdge := Web_StartBtn AND NOT LastWebStartBtn;
LastWebStartBtn := Web_StartBtn;

(* ==================== STUCK INPUT SAFETY ==================== *)
IF (StartBtn OR WebStartBtnRisingEdge) AND NOT StartupFlag THEN
    TagDoneBuzzer := TRUE;
    EXIT;
END_IF;

(* ==================== AUTO ADVANCE ==================== *)
RunDelay(IN := AutoAdvance AND NOT PrinterRunning, PT := T#2s);
IF RunDelay.Q THEN
    Hello := Hello + 1;
    TagDoneBuzzer := FALSE;
    TagDoneProcessed := FALSE;
    TagState := 1;
    AutoAdvance := FALSE;
END_IF;

(* ==================== PULSE AND DELAY TIMERS ==================== *)
PulseTimer(IN := StartupFlag AND (TagState = 1), PT := T#500ms);
IF StartupFlag AND (TagState = 1) AND (NOT PulseTimer.Q) THEN
    RunPulse := TRUE;
    Hello := Hello + 50;
ELSE
    RunPulse := FALSE;
END_IF;
Delay(IN := StartupFlag AND (TagState = 1) AND PulseTimer.Q, PT := T#2s);

(* ==================== SET STATE MACHINE (BATCH CONTROL) ==================== *)
IF (TagIndex > 7) OR (TagIndex >= 8) THEN
    IndexOutOfBounds := TRUE;
    SetState := 0;
    TagState := 0;
    TagDoneBuzzer := TRUE;
    EightDoneBuzzer := TRUE;
    RETURN;
END_IF;

CASE SetState OF
    0: (* Idle - wait for start or web update *)
        IF Web_UpdateFlag OR StartBtnRisingEdge OR WebStartBtnRisingEdge THEN
            IF NumTags > 0 THEN
                SetState := 1;
                TagIndex := 0;
                TagPosition := 0;
                Started := FALSE;
                TagDoneProcessed := FALSE;
                AllBitsProcessed := FALSE;
                AllTagsProcessed := FALSE;
                TagDoneBuzzer := FALSE;
                EightDoneBuzzer := FALSE;
                CurrentTagMask := 0;
                ProcessedMask := 0;
            END_IF;
        END_IF;

    1: (* Process current tag in batch *)
        EightDoneBuzzer := FALSE;

        IF Web_PrintedStatus[EightIndex + TagIndex] = 0 THEN
            IF (AllBitsProcessed AND NOT PrinterRunning AND TagDoneBuzzer) OR (TagList[TagIndex] < 1) THEN
                Web_PrintedStatus[EightIndex + TagIndex] := 1;
                TagDoneProcessed := TRUE;
                TagDoneBuzzer := FALSE;

                IF (TagIndex < 7) AND (TagIndex < (NumTags - 1)) THEN
                    TagIndex := TagIndex + 1;
                    TagPosition := TagPosition + 1;
                    Started := FALSE;
                    AutoAdvance := TRUE;
                    AllBitsProcessed := FALSE;
                    CurrentTagMask := 0;
                    ProcessedMask := 0;
                ELSE
                    EightDoneBuzzer := TRUE;
                    IF TagIndex >= (NumTags - 1) THEN
                        AllTagsProcessed := TRUE;
                    END_IF;
                    SetState := 2;
                    TagIndex := 0;
                    TagPosition := 0;
                END_IF;
            END_IF;
        ELSE
            (* Skip already printed *)
            IF (TagIndex < 7) AND (TagIndex < (NumTags - 1)) THEN
                TagIndex := TagIndex + 1;
                TagPosition := TagPosition + 1;
                Started := FALSE;
            ELSE
                EightDoneBuzzer := TRUE;
                IF TagIndex >= (NumTags - 1) THEN
                    AllTagsProcessed := TRUE;
                END_IF;
                SetState := 2;
                TagIndex := 0;
                TagPosition := 0;
            END_IF;
        END_IF;

    2: (* Batch complete - advance window *)
        IF EightDoneBuzzer AND NOT PrinterRunning THEN
            EightIndex := EightIndex + 8;
            IF EightIndex <= 1999 THEN
                Web_EightIndex := EightIndex;
                FOR i := 0 TO 7 DO
                    IF (EightIndex + i) <= 1999 THEN
                        TagList[i] := Web_TagList[EightIndex + i];
                    ELSE
                        TagList[i] := 0;
                    END_IF;
                END_FOR;
                NumTags := MIN(Web_NumTags - EightIndex, 8);
                IF NumTags < 0 THEN NumTags := 0; END_IF;

                CurrentTagMask := 0;
                ProcessedMask := 0;
                TagIndex := 0;
                TagPosition := 0;
                TagState := 0;
                SetState := 0;
                RunPulse := FALSE;
                LaserPower := FALSE;
                TagDoneBuzzer := FALSE;
                TagDoneProcessed := FALSE;
                Bit1 := FALSE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := FALSE;
                PositionBit0 := FALSE; PositionBit1 := FALSE; PositionBit2 := FALSE;
                Started := FALSE;
                AllBitsProcessed := FALSE;
                AllTagsProcessed := FALSE;
                Web_NextEight := FALSE;
                LastReadyForNextBit := FALSE;
                ReadyForNextBitRisingEdge := FALSE;
            ELSE
                AllTagsProcessed := TRUE;
                SetState := 0;
                EightDoneBuzzer := TRUE;
                IndexOutOfBounds := TRUE;
            END_IF;
        END_IF;
END_CASE;

(* ==================== TAG START: CAPTURE MASK + SET POSITION BITS ==================== *)
IF (NOT Started)
   AND (TagIndex <= (NumTags - 1))
   AND (TagIndex <= 7)
   AND (SetState = 1)
   AND (StartBtnRisingEdge OR WebStartBtnRisingEdge OR AutoAdvance) THEN

    TagNumber := TagList[TagIndex];
    CurrentTagMask := TagNumber;
    ProcessedMask := 0;

    (* Direct 3-bit encoding *)
    PositionBit0 := (TagPosition AND 1) <> 0;
    PositionBit1 := (TagPosition AND 2) <> 0;
    PositionBit2 := (TagPosition AND 4) <> 0;

    Started := TRUE;
    AllBitsProcessed := (CurrentTagMask = 0);

ELSIF TagIndex > 7 THEN
    IndexOutOfBounds := TRUE;
    SetState := 0;
    TagState := 0;
    TagDoneBuzzer := TRUE;
END_IF;

(* ==================== BIT STATE MACHINE ==================== *)
IF (TagIndex > 7) OR (TagIndex >= 8) THEN
    IndexOutOfBounds := TRUE;
    SetState := 0;
    TagState := 0;
    TagDoneBuzzer := TRUE;
    EightDoneBuzzer := TRUE;
    RETURN;
END_IF;

IF SetState = 1 THEN
    IF CurrentTagMask < 1 THEN
        TagDoneBuzzer := TRUE;
        TagState := 0;
    ELSE
        (* Find lowest unprocessed set bit *)
        BitIndex := -1;
        FOR i := 0 TO 9 DO
            IF ((CurrentTagMask AND SHL(1, i)) <> 0)
               AND ((ProcessedMask AND SHL(1, i)) = 0) THEN
                BitIndex := i;
                EXIT;
            END_IF;
        END_FOR;

        IF BitIndex >= 0 THEN
            Channel := BitIndex + 1;

            (* 4-bit binary encoding for channels 1-10 *)
            CASE Channel OF
                1:  Bit1 := TRUE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := FALSE;
                2:  Bit1 := FALSE; Bit2 := TRUE; Bit3 := FALSE; Bit4 := FALSE;
                3:  Bit1 := TRUE; Bit2 := TRUE; Bit3 := FALSE; Bit4 := FALSE;
                4:  Bit1 := FALSE; Bit2 := FALSE; Bit3 := TRUE; Bit4 := FALSE;
                5:  Bit1 := TRUE; Bit2 := FALSE; Bit3 := TRUE; Bit4 := FALSE;
                6:  Bit1 := FALSE; Bit2 := TRUE; Bit3 := TRUE; Bit4 := FALSE;
                7:  Bit1 := TRUE; Bit2 := TRUE; Bit3 := TRUE; Bit4 := FALSE;
                8:  Bit1 := FALSE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := TRUE;
                9:  Bit1 := TRUE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := TRUE;
                10: Bit1 := FALSE; Bit2 := TRUE; Bit3 := FALSE; Bit4 := TRUE;
            ELSE
                Bit1 := FALSE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := FALSE;
            END_CASE;

            CASE TagState OF
                0: (* Wait for trigger *)
                    IF StartBtnRisingEdge OR WebStartBtnRisingEdge OR AutoAdvance THEN
                        TagDoneBuzzer := FALSE;
                        TagDoneProcessed := FALSE;
                        TagState := 1;
                    END_IF;

                1: (* Pulse + settle *)
                    IF Delay.Q THEN
                        IF PrinterRunning THEN
                            TagState := 2;
                        ELSE
                            TagState := 0;
                        END_IF;
                    END_IF;

                2: (* Wait for ready handshake *)
                    IF LaserMode AND PrinterRunning THEN
                        LaserPower := TRUE;
                    ELSE
                        LaserPower := FALSE;
                    END_IF;

                    IF ReadyForNextBitRisingEdge THEN
                        ProcessedMask := ProcessedMask OR SHL(1, BitIndex);
                        Bit1 := FALSE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := FALSE;

                        AllBitsProcessed := ((CurrentTagMask AND (NOT ProcessedMask AND 1023)) = 0);

                        IF AllBitsProcessed THEN
                            Bit1 := FALSE; Bit2 := FALSE; Bit3 := FALSE; Bit4 := FALSE;
                            TagState := 0;
                        ELSE
                            TagState := 1;
                        END_IF;
                    END_IF;
            END_CASE;
        ELSE
            AllBitsProcessed := TRUE;
        END_IF;

        IF (NOT PrinterRunning) AND AllBitsProcessed THEN
            TagDoneBuzzer := TRUE;
            TagState := 0;
            Hello := 300;
        END_IF;
    END_IF;
ELSE
    TagState := 0;
    Bit1 := FALSE;
    Bit2 := FALSE;
    Bit3 := FALSE;
    Bit4 := FALSE;
END_IF;

(* ==================== END OF JOB CLEANUP + MIRRORS ==================== *)
IF AllTagsProcessed AND NOT Web_NextEight THEN
    Bit1 := FALSE;
    Bit2 := FALSE;
    Bit3 := FALSE;
    Bit4 := FALSE;
    RunPulse := FALSE;
    LaserPower := FALSE;
    TagDoneBuzzer := TRUE;
END_IF;

Web_TagPosition := TagPosition;
Web_TagIndex := TagIndex;
