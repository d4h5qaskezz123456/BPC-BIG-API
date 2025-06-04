tableextension 80011 "BPC.LSC Tender Type" extends "LSC Tender Type"
{
    fields
    {
        field(80100; "BPC.POS VAT Code"; code[10])
        {
            Caption = 'POS VAT Code';
            TableRelation = "LSC POS VAT Code"."VAT Code";
        }

    }

    var
}