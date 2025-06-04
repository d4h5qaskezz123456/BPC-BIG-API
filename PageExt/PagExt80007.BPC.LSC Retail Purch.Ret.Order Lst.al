pageextension 80007 "BPCLSCRetailPurchRetOrderLst" extends "LSC Retail Purch.Ret.Order Lst"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // modify(Post)


    }

    // trigger OnOpenPage()
    // var
    //     RetailSetup: Record "LSC Retail Setup";
    // begin
    //     RetailSetup.Get();
    //     if RetailSetup."BPC.Interface D365 Active" then
    //         InterfaceData.GetPurchaseHeader();
    // end;

    var
        RetailSetup: Record "LSC Retail Setup";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        InterfaceData: Codeunit "BPC.Interface Data";
}