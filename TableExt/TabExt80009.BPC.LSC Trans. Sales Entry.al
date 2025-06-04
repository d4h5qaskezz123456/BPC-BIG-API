tableextension 80009 "BPC.LSC TransSalesEntry" extends "LSC Trans. Sales Entry"
{
    fields
    {
        field(80100; "BPC.Sales Location"; Code[10])
        {
            Caption = 'Sales Location';
            TableRelation = Location;
        }
        field(80101; "BPC.Line No. Text"; Text[2000])
        {
            Caption = 'Line No. Text';
        }

    }


    var

}