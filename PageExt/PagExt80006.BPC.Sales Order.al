pageextension 80006 "BPC Sales Order" extends "Sales Order"
{
    layout
    {
    }

    actions
    {

    }

    // trigger OnOpenPage()
    // var

    // begin
    //     RetailSetup.GET();
    //     IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
    //         InterfaceData.GetSalesLine(Rec);
    //     END;
    // end;

    var
        RetailSetup: Record "LSC Retail Setup";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        InterfaceData: Codeunit "BPC.Interface Data";
}