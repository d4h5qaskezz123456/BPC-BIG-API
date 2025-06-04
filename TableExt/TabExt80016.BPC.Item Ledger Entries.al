tableextension 80016 "BPC.Item Ledger Entries" extends "Item Ledger Entry"
{
    fields
    {
        field(80101; "BPC.Statement No."; Code[20])
        {
            Caption = 'POS VAT Code';
        }

    }
    trigger OnInsert()
    var
        myInt: Integer;
    begin
        "BPC.Statement No." := UserId;
    end;

    var
}