table 80002 "BPC.Interface Log API"
{

    fields
    {
        field(80000; "BPC.Interface Type"; Text[50])
        {
            Caption = 'Interface Type';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(80001; "BPC.Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Entry No.';
        }
        field(80002; "BPC.D365 Response Log"; BLOB)
        {
            Caption = 'D365 Response Log';
            DataClassification = ToBeClassified;
        }
        field(80003; "BPC.Interface Date"; Date)
        {
            Caption = 'Interface Date';
            DataClassification = ToBeClassified;
        }
        field(80004; "BPC.Interface Time"; Time)
        {
            Caption = 'Interface Time';
            DataClassification = ToBeClassified;
        }
        field(80005; "BPC.Interface DateTime"; DateTime)
        {
            Caption = 'Interface DateTime';
            DataClassification = ToBeClassified;
        }
        field(80006; "BPC.Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(80007; "BPC.Interface URL"; Text[250])
        {
            Caption = 'Interface URL';
            DataClassification = ToBeClassified;
        }
        field(80008; "BPC.Request D365 Log"; BLOB)
        {
            Caption = 'Request D365 Log';
            DataClassification = ToBeClassified;
        }
        field(80009; "BPC.Error Occur"; Boolean)
        {
            Caption = 'Error Occur';
            DataClassification = ToBeClassified;
        }
        field(80010; "BPC.User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = ToBeClassified;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "BPC.Interface Type", "BPC.Document No.", "BPC.Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "BPC.Interface DateTime")
        {
        }
        key(Key3; "BPC.Interface DateTime", "BPC.Interface Type", "BPC.Document No.", "BPC.Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure SetRequestD365(NewText: Text; Encoding: TextEncoding)
    var
        TempBlob: Record "BPC.TempBlob" temporary;
    begin
        CLEAR("BPC.Request D365 Log");
        IF NewText = '' THEN
            EXIT;
        TempBlob.Blob := "BPC.Request D365 Log";
        TempBlob.WriteAsText(NewText, Encoding);
        "BPC.Request D365 Log" := TempBlob.Blob;
        MODIFY;
    end;

    procedure GetRequestD365(Encoding: TextEncoding): Text
    var
        TempBlob: Record "BPC.TempBlob" temporary;
        CR: Text[1];
    begin
        CALCFIELDS("BPC.Request D365 Log");
        IF NOT "BPC.Request D365 Log".HASVALUE THEN
            EXIT('');
        CR[1] := 10;
        TempBlob.Blob := "BPC.Request D365 Log";
        EXIT(TempBlob.ReadAsText(CR, Encoding));
    end;

    procedure SetD365Response(NewText: Text; Encoding: TextEncoding)
    var
        TempBlob: Record "BPC.TempBlob" temporary;
    begin
        CLEAR("BPC.D365 Response Log");
        IF NewText = '' THEN
            EXIT;
        TempBlob.Blob := "BPC.D365 Response Log";
        TempBlob.WriteAsText(NewText, Encoding);
        "BPC.D365 Response Log" := TempBlob.Blob;
        MODIFY;
    end;

    procedure GetD365Response(Encoding: TextEncoding): Text
    var
        TempBlob: Record "BPC.TempBlob" temporary;
        CR: Text[1];
    begin
        CALCFIELDS("BPC.D365 Response Log");
        IF NOT "BPC.D365 Response Log".HASVALUE THEN
            EXIT('');
        CR[1] := 10;
        TempBlob.Blob := "BPC.D365 Response Log";
        EXIT(TempBlob.ReadAsText(CR, Encoding));
    end;

    procedure RunEntryNo(InterfaceType: Text[50]; DocNo: Code[20]) EntryNo: Integer
    var
        InterfaceLogDRL: Record "BPC.Interface Log API";
    begin
        CLEAR(EntryNo);
        InterfaceLogDRL.RESET;
        InterfaceLogDRL.SETFILTER("BPC.Interface Type", '%1', InterfaceType);
        InterfaceLogDRL.SETFILTER("BPC.Document No.", '%1', DocNo);
        IF InterfaceLogDRL.FINDLAST THEN
            EntryNo := InterfaceLogDRL."BPC.Entry No." + 10000
        ELSE
            EntryNo := 10000;
    end;
}

