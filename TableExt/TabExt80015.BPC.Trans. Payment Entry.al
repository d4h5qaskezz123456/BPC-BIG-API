tableextension 80015 "BPC.Trans. Payment Entry" extends "LSC Trans. Payment Entry"
{
    fields
    {
        field(80100; "BPC.POS VAT Code"; Code[10])
        {
            Caption = 'POS VAT Code';
        }
        field(80101; "BPC.POS VAT%"; Decimal)
        {
            Caption = 'POS VAT%';
        }
        field(80102; "BPC.POS VAT Amount"; Decimal)
        {
            Caption = 'POS VAT Amount';
        }
        field(80103; "BPC.POS VAT Excd. VAT"; Decimal)
        {
            Caption = 'POS VAT Excd. VAT';
        }

    }
    var
}