page 80020 "BPC.API.SalesOrderLineV3"
{
    PageType = API;
    Caption = 'Sales Order Line';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v3.0';
    EntityName = 'salesOrderLine';
    EntitySetName = 'salesOrderLines';
    SourceTable = "BPC.API Sales&PurchaseHdrBuff";
    SourceTableTemporary = true;
    DelayedInsert = true;
    ODataKeyFields = Company, "No.";

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(company; Rec.Company) { }
                field(warehouse; Rec."Location Code") { }
                field(data; Data)
                {
                    Caption = 'Data';
                    trigger OnValidate()
                    var
                        ItemsNotExist: Text;
                        ItemsNotExistLbl: Label 'Item Number does not exist: (%1)';
                    // SalesHeader: Record "Sales Header";
                    // DocumentPendingLbl: Label 'Sales Order %1 have pending Posted Document';
                    begin
                        if not BCPInterfaceDataCU.ItemExist(Data, ItemsNotExist) then
                            ErrorMsg := StrSubstNo(ItemsNotExistLbl, ItemsNotExist);

                        // if ErrorMsg = '' then
                        //     if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."No.") then
                        //         if not BCPInterfaceDataCU.CheckExistPostedPending(SalesHeader."No.") then
                        //             ErrorMsg := StrSubstNo(DocumentPendingLbl, SalesHeader."No.");
                    end;
                }
                field(salesOrder; Rec."No.") { Caption = 'Sales Order'; }
                field(errorMsg; ErrorMsg) { }
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
        ErrorMsg: Text;

    local procedure ProcessData(pRec: Record "BPC.API Sales&PurchaseHdrBuff" temporary)
    var
        SalesHeader: Record "Sales Header";
        ReleaseSaleshDoc: Codeunit "Release Sales Document";
    begin
        BCPInterfaceDataCU.InsertInterfaceLog('salesOrderLines', Data, 'salesOrderLines', '', pRec."No.", FALSE);

        if SalesHeader.Get(SalesHeader."Document Type"::Order, pRec."No.") then begin
            BCPInterfaceDataCU.GenerateTempSalesOrder(FALSE, Data, SalesHeader);
            if not BCPInterfaceDataCU.CheckExistPostedPending(SalesHeader."No.") then begin
                ReleaseSaleshDoc.PerformManualReopen(SalesHeader);
                BCPInterfaceDataCU.InsertSalesOrder(FALSE, SalesHeader."LSC Store No.", SalesHeader."Location Code", SalesHeader);
                ReleaseSaleshDoc.PerformManualRelease(SalesHeader);
            end;
        end;
    end;
}