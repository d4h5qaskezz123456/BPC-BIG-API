pageextension 80008 "BPCLSCRetailPurchReturnOrder" extends "LSC Retail Purch. Return Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // modify("P&ost")


    }

    trigger OnOpenPage()
    var
        RetailSetup: Record "LSC Retail Setup";
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" then
            if Rec.Status = rec.Status::Cancel then
                Error('PO Cancel');
        // if RetailSetup."BPC.Interface D365 Active" then
        //     if Rec.Status <> rec.Status::Cancel then
        //         InterfaceData.GetPurchaseLine(Rec)
        //     else
        //         Error('PO Cancel');
    end;

    var
        RetailSetup: Record "LSC Retail Setup";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        InterfaceData: Codeunit "BPC.Interface Data";
}