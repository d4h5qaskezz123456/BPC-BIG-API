pageextension 80011 "BPC.LSCRetailSalesOrderList" extends "LSC Retail Sales Order List"
{
    layout
    {


    }

    actions
    {

    }
    trigger OnOpenPage()
    var
        RetailSetup: Record "LSC Retail Setup";
    begin
        // RetailSetup.Get();
        // if RetailSetup."BPC.Interface D365 Active" then
        //     InterfaceData.GetSalesHeader();
    end;

    var
        InterfaceData: Codeunit "BPC.Interface Data";


}