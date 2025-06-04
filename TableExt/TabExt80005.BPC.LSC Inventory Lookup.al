tableextension 80005 "BPC.LSC Inventory Lookup Table" extends "LSC Inventory Lookup Table"
{
    fields
    {

        field(80100; "BPC.Stock On D365"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Stock On D365';
        }
        field(80101; "BPC.Qty. Sold not Posted"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Qty. Sold not Posted';
        }

        field(80102; "BPC.Net Inventory 2"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Net Inventory 2';
        }

    }
    procedure UpdateInventory2()
    var
    begin
        "BPC.Qty. Sold not Posted" := BOUtil.ReturnQtySoldNotPosted("Item No.", "Store No.", Location, "Variant Code", '');
        "BPC.Net Inventory 2" := "BPC.Qty. Sold not Posted" - "BPC.Stock On D365";
    end;

    var
        BOUtil: Codeunit "LSC BO Utils";

}