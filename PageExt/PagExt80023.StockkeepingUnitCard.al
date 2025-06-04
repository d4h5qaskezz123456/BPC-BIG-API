pageextension 80023 "BPC.StockkeepingUnitCard" extends "Stockkeeping Unit Card"
{
    layout
    {
        addlast(General)
        {
            field("BPC.Brand"; Rec."BPC.Brand")
            {
                ApplicationArea = All;
            }
        }
        modify(Invoicing)
        {
            Visible = false;
        }
    }

    actions
    {
    }
}