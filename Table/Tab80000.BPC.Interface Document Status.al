table 80000 "BPC.Interface Document Status"
{

    fields
    {
        field(80000; "BPC.Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = 'GRN,Statement';
            OptionMembers = GRN,Statement;
            Caption = 'Document Type';
        }
        field(80001; "BPC.Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(80002; "BPC.Interface Date-Time"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Interface Date-Time';
        }
        field(80003; "BPC.Interface Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Interface Entry No.';
        }
        field(80004; "BPC.Posted At FO"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Posted At FO';
        }
        field(80005; "BPC.Reference Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Reference Document No.';
        }
    }

    keys
    {
        key(Key1; "BPC.Document Type", "BPC.Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

