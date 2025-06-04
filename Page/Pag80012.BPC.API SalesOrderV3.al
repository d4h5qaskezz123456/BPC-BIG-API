page 80012 "BPC.API.SalesOrderV3"
{
    PageType = API;
    Caption = 'Sales Order';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v3.0';
    EntityName = 'salesOrder';
    EntitySetName = 'salesOrders';
    SourceTable = "BPC.API Sales&PurchaseHdrBuff";
    SourceTableTemporary = true;
    DelayedInsert = true;
    ODataKeyFields = Company;
    layout
    {
        area(Content)
        {
            repeater(GroupConnect)
            {
                field(company; Rec.Company) { }
                field(warehouse; Rec."Location Code") { }
                field(data; Data) { Caption = 'Data'; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ProcessData(Rec);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ProcessData(Rec);
        exit(false);
    end;

    var
        BCPInterfaceDataCU: Codeunit "BPC.Interface Data";
        Data: Text;

    local procedure ProcessData(pRec: Record "BPC.API Sales&PurchaseHdrBuff" temporary)
    var
        SalesHeader: Record "Sales Header";
        StoreLocation: Record "LSC Store Location";
        StoreNo: Code[10];
    begin
        StoreLocation.SetRange("Location Code", pRec."Location Code");
        if StoreLocation.FindFirst() then
            StoreNo := StoreLocation."Store No.";

        BCPInterfaceDataCU.InsertInterfaceLog('salesOrders', Data, 'salesOrders', '', '', FALSE);
        BCPInterfaceDataCU.GenerateTempSalesOrder(TRUE, Data, SalesHeader);
        BCPInterfaceDataCU.InsertSalesOrder(TRUE, StoreNo, pRec."Location Code", SalesHeader);
    end;

}