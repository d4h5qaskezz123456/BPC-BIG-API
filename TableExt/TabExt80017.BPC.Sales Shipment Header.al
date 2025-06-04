tableextension 80017 "BPC.Sales Shipment Header" extends "Sales Shipment Header"
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
        field(80102; "BPC.File PDF"; MediaSet)
        {
            Caption = 'File PDF';
        }
        field(80103; "BPC.Location Code"; Code[10])
        {

        }
    }
    trigger OnInsert()
    var
        myInt: Integer;
    begin
    end;

    var
}