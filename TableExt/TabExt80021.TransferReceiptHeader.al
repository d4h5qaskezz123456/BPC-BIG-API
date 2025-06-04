tableextension 80198 "Transfer Receipt Header" extends "Transfer Receipt Header"
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
