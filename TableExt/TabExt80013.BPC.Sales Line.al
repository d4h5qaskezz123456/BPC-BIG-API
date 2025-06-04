tableextension 80013 "BPC.Sales Line" extends "Sales Line"
{
    fields
    {
        field(80100; "BPC.Interface"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Interface';
        }
        field(80101; "BPC.Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(80102; "BPC.Not Check AutoAsmToOrder"; Boolean)
        {
            Caption = 'Not Check AutoAsmToOrder';
            Editable = false;
        }
    }

    var
}