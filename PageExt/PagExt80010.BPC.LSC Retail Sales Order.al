pageextension 80010 "BPC.LSC Retail Sales Order" extends "LSC Retail Sales Order"
{
    layout
    {


    }

    actions
    {
        addafter("Prepa&yment Invoices")
        {
            action(AssemblyOrders)
            {
                AccessByPermission = TableData "BOM Component" = R;
                ApplicationArea = Assembly;
                Caption = 'Assembly Orders';
                Image = AssemblyOrder;
                ToolTip = 'View ongoing assembly orders related to the sales order. ';

                trigger OnAction()
                var
                    AssembleToOrderLink: Record "Assemble-to-Order Link";
                begin
                    AssembleToOrderLink.ShowAsmOrders(Rec);
                end;
            }
        }
    }
    trigger OnOpenPage()
    var

    begin
        RetailSetup.GET();
        if rec.Status = rec.Status::Cancel then
            Error('SO Cancel');

        // IF RetailSetup."BPC.Interface D365 Active" THEN BEGIN
        //     InterfaceData.GetSalesLine(Rec);

        // END;
    end;

    var
        RetailSetup: Record "LSC Retail Setup";
        InterfaceData: Codeunit "BPC.Interface Data";

}