table 80009 "BPC.API Log Member Contact"
{
    Caption = 'API Log Member Contact';
    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(2; "Method Name"; Text[100])
        {
        }
        field(3; Description; Text[1000])
        {
        }
        field(4; "Created DateTime"; DateTime)
        {
        }
        field(5; "Created Date"; Date)
        {
        }
        field(6; "Created Time"; Time)
        {
        }
        field(7; "Employee No."; Code[20])
        {
            TableRelation = User;
        }
        field(8; Status; Option)
        {
            OptionMembers = Success,Error;
            OptionCaption = 'Success,Error';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure InitEnty(NewMethodName: Text[100]; NewDescription: Text[1000]; NewEmployeeNo: Code[20]; NewStatus: Option)
    begin
        Init();
        "Method Name" := NewMethodName;
        Description := NewDescription;
        "Employee No." := NewEmployeeNo;
        Status := NewStatus;
        "Created DateTime" := CurrentDateTime;
        "Created Date" := DT2Date("Created DateTime");
        "Created Time" := DT2Time("Created DateTime");
    end;

    procedure GetNextEntryNo(): Integer
    var
        APILog: Record "BPC.API Log Member Contact";
    begin
        APILog.LockTable();
        if APILog.FindLast() then
            exit(APILog."Entry No." + 1);
        exit;
    end;
}