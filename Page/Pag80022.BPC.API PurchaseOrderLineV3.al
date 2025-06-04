page 80024 "BPC.API.PurchaseOrderLineV3"
{
    PageType = API;
    Caption = 'Purchase Order Line';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v3.0';
    EntityName = 'purchaseOrderLine';
    EntitySetName = 'purchaseOrderLines';
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
                    begin
                        if not BCPInterfaceDataCU.ItemExist(Data, ItemsNotExist) then
                            ErrorMsg := StrSubstNo(ItemsNotExistLbl, ItemsNotExist);
                    end;
                }
                field(purchaseOrder; Rec."No.") { Caption = 'Purchase Order'; }
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
        PurchaseHeader: Record "Purchase Header";
        InterfaceDocumentStatus: Record "BPC.Interface Document Status";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        DocumentPendingLbl: Label 'Purchase Order %1 have pending Posted Document\GRN No.: %2';
    begin
        BCPInterfaceDataCU.InsertInterfaceLog('purchaseOrderLines', Data, 'purchaseOrderLines', '', pRec."No.", FALSE);
        // Joe 2025-03-28: Don't create po line when error no item ++
        if ErrorMsg <> '' then
            exit;
        // Joe 2025-03-28: Don't create po line when error no item --

        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, pRec."No.") then begin
            BCPInterfaceDataCU.GenerateTempPurchOrder(FALSE, Data, PurchaseHeader);
            if not BCPInterfaceDataCU.CheckExistPostedPending(PurchaseHeader."No.") then begin
                ReleasePurchDoc.PerformManualReopen(PurchaseHeader);
                BCPInterfaceDataCU.InsertPurchOrder(FALSE, PurchaseHeader."LSC Store No.", PurchaseHeader."Location Code");
                PurchaseHeader.Status := PurchaseHeader.Status::Released;
                PurchaseHeader.Modify();
            end else begin
                InterfaceDocumentStatus.RESET();
                InterfaceDocumentStatus.SETRANGE("BPC.Document Type", InterfaceDocumentStatus."BPC.Document Type"::GRN);
                InterfaceDocumentStatus.SETRANGE("BPC.Reference Document No.", PurchaseHeader."No.");
                if InterfaceDocumentStatus.FindFirst() then
                    Error('Purchase Order %1 have pending Posted Document\GRN No.: %2', PurchaseHeader."No.", InterfaceDocumentStatus."BPC.Document No.");
                // ErrorMsg := StrSubstNo(DocumentPendingLbl, PurchaseHeader."No.", InterfaceDocumentStatus."BPC.Document No.");
            end;
        end;
    end;


}