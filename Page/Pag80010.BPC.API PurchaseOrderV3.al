page 80011 "BPC.API.PurchaseOrderV3"
{
    PageType = API;
    Caption = 'Purchase Order';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v3.0';
    EntityName = 'purchaseOrder';
    EntitySetName = 'purchaseOrders';
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
        PurchHeader: Record "Purchase Header";
        StoreLocation: Record "LSC Store Location";
        StoreNo: Code[10];
    begin
        StoreLocation.SetRange("Location Code", pRec."Location Code");
        if StoreLocation.FindFirst() then
            StoreNo := StoreLocation."Store No.";

        BCPInterfaceDataCU.InsertInterfaceLog('purchaseOrders', Data, 'purchaseOrders', '', '', FALSE);
        BCPInterfaceDataCU.GenerateTempPurchOrder(TRUE, Data, PurchHeader);
        BCPInterfaceDataCU.InsertPurchOrder(TRUE, StoreNo, pRec."Location Code");
    end;
}