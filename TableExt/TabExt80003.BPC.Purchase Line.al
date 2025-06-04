tableextension 80003 "BPC Purchase Line" extends "Purchase Line"
{
    fields
    {

        field(80100; "BPC.Interface"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(80101; "BPC.Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = ToBeClassified;
            Editable = false;
        }

    }

    var

}