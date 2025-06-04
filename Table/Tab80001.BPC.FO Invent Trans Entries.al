table 80001 "BPC.FO - Invent Trans Entries"
{
    Caption = 'FO - Invent Trans Entries';

    fields
    {
        field(80000; "BPC.Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Entry No.';
        }
        field(80001; "BPC.Replication Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Replication Code';
        }
        field(80002; "BPC.Physical Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Physical Date';
        }
        field(80003; "BPC.Document No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(80004; "BPC.Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Item No.';
        }
        field(80005; "BPC.Item Description"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Item Description';
        }
        field(80006; "BPC.Variant Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Variant Code';
        }
        field(80007; "BPC.Variant Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Variant Name';
        }
        field(80008; "BPC.Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantity';
        }
        field(80009; "BPC.Location Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Location Code';
        }
        field(80010; "BPC.Serial No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Serial No.';
        }
        field(80011; "BPC.Lot No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Lot No.';
        }
        field(80012; "BPC.Expiration Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Expiration Date';
        }
        field(80013; "BPC.Reference Lot No."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Reference Lot No.';
        }
    }

    keys
    {
        key(Key1; "BPC.Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        Rec2: Record "Requisition Line";
    begin
    end;

    [Scope('Internal')]
    procedure GetLastEntryNo(): Integer
    var
        PostedPRLine: Record "BPC.FO - Invent Trans Entries";
    begin
        PostedPRLine.RESET;
        PostedPRLine.SETCURRENTKEY("BPC.Entry No.");
        IF PostedPRLine.FINDLAST THEN
            EXIT(PostedPRLine."BPC.Entry No." + 1);
        EXIT(1);
    end;
}

