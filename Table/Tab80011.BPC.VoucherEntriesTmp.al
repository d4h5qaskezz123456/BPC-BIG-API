table 80011 "BPC.Voucher Entries Tmp"
{
    Caption = 'Voucher Entries Tmp';
    DrillDownPageID = "LSC Voucher Entries";
    LookupPageID = "LSC Voucher Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Voucher No."; Code[20])
        {
            Caption = 'Voucher No.';
            DataClassification = CustomerContent;
        }
        field(2; "Store No."; Code[10])
        {
            Caption = 'Store No.';
            TableRelation = "LSC Store";
            DataClassification = CustomerContent;
        }
        field(3; "POS Terminal No."; Code[10])
        {
            Caption = 'POS Terminal No.';
            DataClassification = CustomerContent;
        }
        field(4; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = CustomerContent;
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(6; "Receipt Number"; Code[20])
        {
            Caption = 'Receipt Number';
            DataClassification = CustomerContent;
        }
        field(7; Unposted; Boolean)
        {
            Caption = 'Unposted';
            DataClassification = CustomerContent;
        }
        field(8; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Issued,Redemption';
            OptionMembers = Issued,Redemption;
            DataClassification = CustomerContent;
        }
        field(9; Date; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(10; Time; Time)
        {
            Caption = 'Time';
            DataClassification = CustomerContent;
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(12; Voided; Boolean)
        {
            Caption = 'Voided';
            DataClassification = CustomerContent;
        }
        field(13; "Remaining Amount Now"; Decimal)
        {
            Caption = 'Remaining Amount Now';
            DataClassification = CustomerContent;
        }
        field(14; "Replication Counter"; Integer)
        {
            Caption = 'Replication Counter';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                VoucherEntries: Record "LSC Voucher Entries";
                ClientSessionUtility: Codeunit "LSC Client Session Utility";
            begin
                if not ClientSessionUtility.UpdateReplicationCountersForTable(RecordId, "Replication Counter") then
                    exit;

                VoucherEntries.Reset;
                VoucherEntries.SetCurrentKey("Replication Counter");
                if VoucherEntries.Find('+') then
                    "Replication Counter" := VoucherEntries."Replication Counter" + 1
                else
                    "Replication Counter" := 1;
            end;
        }
        field(15; "One Time Redemption"; Boolean)
        {
            Caption = 'One Time Redemption';
            DataClassification = CustomerContent;
        }
        field(16; "Write Off Amount"; Decimal)
        {
            Caption = 'Write Off Amount';
            DataClassification = CustomerContent;
        }
        field(17; "Voucher Type"; Code[10])
        {
            Caption = 'Voucher Type';
            DataClassification = CustomerContent;
        }
        field(18; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
        field(19; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            InitValue = 0;
            DataClassification = CustomerContent;
        }
        field(20; "Amount In Store Currency"; Decimal)
        {
            Caption = 'Amount In Store Currency';
            DataClassification = CustomerContent;
        }
        field(21; "Store Currency Code"; Code[10])
        {
            Caption = 'Store Currency Code';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
        field(22; "Return Deposit"; Boolean)
        {
            Caption = 'Return Deposit';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
    }


    keys
    {
        key(Key1; "Store No.", "POS Terminal No.", "Transaction No.", "Line No.", "Receipt Number")
        {
            Clustered = true;
        }
        key(Key2; "Voucher No.", "Entry Type", Voided)
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Receipt Number", "Store No.", "POS Terminal No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
        key(Key4; "Replication Counter")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Validate("Replication Counter");
    end;

    trigger OnModify()
    begin
        Validate("Replication Counter");
    end;
}