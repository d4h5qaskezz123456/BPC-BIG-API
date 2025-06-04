tableextension 80199 "Transfer Shipment Header" extends "Transfer Shipment Header"
{
    fields
    {
        field(80100; "BPC Send To FO"; Boolean)
        {
            Caption = 'Send To FO';
            DataClassification = CustomerContent;
        }
    }
}
