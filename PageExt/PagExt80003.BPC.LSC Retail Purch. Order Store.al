pageextension 80003 "BPC.LSCRetailPurch.OrderStore" extends "LSC Retail Purch. Order Store"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // modify(Post)


    }

    trigger OnOpenPage()
    var
        RetailSetup: Record "LSC Retail Setup";
        LSCRetailUser: Record "LSC Retail User";
    begin
        LSCRetailUser.Reset();
        LSCRetailUser.SetRange(ID, UserId);
        if LSCRetailUser.FindSet() then
            LSCRetailUser.TestField("Store No.");
        // RetailSetup.Get();
        // if RetailSetup."BPC.Interface D365 Active" then
        //     InterfaceData.GetPurchaseHeader();
    end;

    var
        InterfaceData: Codeunit "BPC.Interface Data";
}