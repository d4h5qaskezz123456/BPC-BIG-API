codeunit 80002 "BPC.Event Subsciber"
{
    Permissions = TableData 32 = rimd;
    //SendUndoShipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterCode', '', true, true)]
    local procedure OnAfterCode(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" then
            InterfaceData.SendUndoShipment(SalesShipmentLine);
    end;

    //SendUndoReceipt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterCode', '', true, true)]
    local procedure BPCOnAfterCode(var PurchRcptLine: Record "Purch. Rcpt. Line"; var UndoPostingManagement: Codeunit "Undo Posting Management")
    var
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" then
            InterfaceData.SendUndoReceipt(PurchRcptLine);
    end;

    //PostTransferShipment PostTransfersReceipt //oat
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post (Yes/No)", OnAfterPost, '', true, true)]
    local procedure BPCOnAfterPostTransfer(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    var
        Location: Record Location;
        TransferShipmentHeader: record "Transfer Shipment Header";
        TransferReceiptHeader: record "Transfer Receipt Header";
        ResendInterfaceData: Codeunit "BPC.ReSend Interface";
        ErrText: Text;
    begin
        RetailSetup.Get();

        if not Location.Get(TransHeader."Transfer-from Code") then
            Location.Init();

        case Selection of
            Selection::Shipment:
                if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
                    TransferShipmentHeader.Reset();
                    TransferShipmentHeader.SetRange("Transfer Order No.", TransHeader."No.");
                    if TransferShipmentHeader.FindFirst() then begin
                        ResendInterfaceData.ReSendPostTransfersShipment(TransferShipmentHeader);
                        TransferShipmentHeader."BPC Send To FO" := true;
                        TransferShipmentHeader.Modify();
                    end;
                end;
            Selection::Receipt:
                if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
                    TransferReceiptHeader.Reset();
                    TransferReceiptHeader.SetRange("Transfer Order No.", TransHeader."No.");
                    if TransferReceiptHeader.FindFirst() then begin
                        ResendInterfaceData.ReSendPostTransfersReceipt(TransferReceiptHeader, false, ErrText);
                        TransferReceiptHeader."BPC Send To FO" := true;
                        TransferReceiptHeader.Modify();
                    end;
                end;
        end;
    end;

    //PostTransferShipment PostTransfersReceipt Post + Print
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post + Print", 'OnAfterPost', '', true, true)]
    local procedure BPCOnAfterPostPrint(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    var
        Location: Record Location;
        TransferShipmentHeader: record "Transfer Shipment Header";
        TransferReceiptHeader: record "Transfer Receipt Header";
        ResendInterfaceData: Codeunit "BPC.ReSend Interface";
        ErrText: Text;
    begin
        RetailSetup.Get();

        if not Location.Get(TransHeader."Transfer-from Code") then
            Location.Init();

        case Selection of
            Selection::Shipment:
                if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
                    TransferShipmentHeader.Reset();
                    TransferShipmentHeader.SetRange("Transfer Order No.", TransHeader."No.");
                    if TransferShipmentHeader.FindFirst() then begin
                        ResendInterfaceData.ReSendPostTransfersShipment(TransferShipmentHeader);
                        TransferShipmentHeader."BPC Send To FO" := true;
                        TransferShipmentHeader.Modify();
                    end;
                end;
            Selection::Receipt:
                if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
                    TransferReceiptHeader.Reset();
                    TransferReceiptHeader.SetRange("Transfer Order No.", TransHeader."No.");
                    if TransferReceiptHeader.FindFirst() then begin
                        ResendInterfaceData.ReSendPostTransfersReceipt(TransferReceiptHeader, false, ErrText);
                        TransferReceiptHeader."BPC Send To FO" := true;
                        TransferReceiptHeader.Modify();
                    end;
                end;
        end;
    end;

    //PostSalesShipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnAfterPost', '', true, true)]
    local procedure BPCOnAfterPost(var SalesHeader: Record "Sales Header")
    var
        InterfaceData: Codeunit "BPC.Interface Data";
        ErrText: Text;
        Window: Dialog;
    begin
        RetailSetup.Get();
        if SalesHeader.Ship then
            if RetailSetup."bpc.Interface D365 Active" then begin
                Window.Open('Posting to F&O...');
                InterfaceData.PostSalesShipment(SalesHeader, false, ErrText);
                Window.Close();
            end;
    end;

    //หลัง PostPurchaseReceive SendPurchaseReceive ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterPost', '', true, true)]
    local procedure OnAfterPost(var PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        InterfaceData: Codeunit "BPC.Interface Data";
        Window: Dialog;
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" and PurchaseHeader.Receive then begin
            Window.Open('Posting to F&O...');
            PurchRcptHeader.Reset();
            PurchRcptHeader.SetCurrentKey("No.");
            PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
            if PurchRcptHeader.FindLast() then
                InterfaceData.SendPurchaseReceive(PurchaseHeader, PurchRcptHeader."No.");
            Window.Close();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post + Print", 'OnAfterPost', '', true, true)]
    local procedure OnAfterPostPurportandprint(var PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        InterfaceData: Codeunit "BPC.Interface Data";
        Window: Dialog;
    begin
        RetailSetup.Get();
        if RetailSetup."BPC.Interface D365 Active" and PurchaseHeader.Receive then begin
            Window.Open('Posting to F&O...');
            PurchRcptHeader.Reset();
            PurchRcptHeader.SetCurrentKey("No.");
            PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
            if PurchRcptHeader.FindLast() then
                InterfaceData.SendPurchaseReceive(PurchaseHeader, PurchRcptHeader."No.");
            Window.Close();
        end;
    end;
    //หลัง PostPurchaseReceive SendPurchaseReceive --

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterReturnShptLineInsert', '', true, true)]
    local procedure BPCOnAfterReturnShptLineInsert(var ReturnShptLine: Record "Return Shipment Line"; ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; xPurchLine: Record "Purchase Line")
    begin
        LSGRNNo := ReturnShptLine."Document No.";

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchRcptLineInsert', '', true, true)]
    local procedure BPCOnAfterPurchRcptLineInsert(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSupressed: Boolean; PurchInvHeader: Record "Purch. Inv. Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; PurchRcptHeader: Record "Purch. Rcpt. Header"; TempWhseRcptHeader: Record "Warehouse Receipt Header"; xPurchLine: Record "Purchase Line"; var TempPurchLineGlobal: Record "Purchase Line" temporary)
    begin
        LSGRNNo := PurchRcptLine."Document No.";
    end;

    procedure GetGRNNo(var pGRNNo: Code[20])
    begin
        pGRNNo := LSGRNNo;
    end;

    // SendExpense
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', true, true)]
    local procedure BPCOnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    var
        LocRetailSetup: Record "LSC Retail Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        InterfaceData: Codeunit "BPC.Interface Data";
        ErrText: Text;
    begin
        LocRetailSetup.Get();
        if (LocRetailSetup."BPC.Interface D365 Active") and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice) then begin
            PurchInvHeader.Reset();
            PurchInvHeader.SetRange("No.", PurchInvHdrNo);
            if PurchInvHeader.FindSet() then
                InterfaceData.SendExpense(PurchInvHeader, PurchInvHdrNo, false, ErrText);
        end;
    end;

    //InsertPaymentEntry
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnBeforeInsertPaymentEntryV2', '', true, true)]
    local procedure BPCOnBeforeInsertPaymentEntryV2(var POSTransaction: Record "LSC POS Transaction"; var POSTransLineTemp: Record "LSC POS Trans. Line" temporary; var TransPaymentEntry: Record "LSC Trans. Payment Entry")
    var
        InfocodeEntry: Record "LSC POS Trans. Infocode Entry";
        TenderTypes: Record "LSC Tender Type";
        POSVAT: Record "LSC POS VAT Code";
        POSDataEntry: Record "LSC POS Data Entry";
        item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not TenderTypes.Get(POSTransaction."Store No.", POSTransLineTemp.Number) then
            TenderTypes.Init();

        InfocodeEntry.Reset();
        InfocodeEntry.SetRange("Receipt No.", POSTransLineTemp."Receipt No.");
        InfocodeEntry.SetRange("Transaction Type", InfocodeEntry."Transaction Type"::"Payment Entry");
        InfocodeEntry.SetRange("Line No.", POSTransLineTemp."Line No.");
        InfocodeEntry.SetRange(Infocode, 'DP-USED');
        if InfocodeEntry.IsEmpty() then begin
            if TenderTypes."BPC.POS VAT Code" <> '' then begin
                POSVAT.Get(TenderTypes."BPC.POS VAT Code");
                TransPaymentEntry."BPC.POS VAT Code" := POSVAT."VAT Code";
                TransPaymentEntry."BPC.POS VAT%" := POSVAT."VAT %";
                TransPaymentEntry."BPC.POS VAT Amount" := Round(TransPaymentEntry."Amount Tendered" * (POSVAT."VAT %" / (100 + POSVAT."VAT %")), 0.01);
                TransPaymentEntry."BPC.POS VAT Excd. VAT" := TransPaymentEntry."Amount Tendered" - TransPaymentEntry."BPC.POS VAT Amount";
            end;
        end else
            if POSDataEntry.Get('DEPOSIT', InfocodeEntry.Infocode) then
                if item.Get(POSDataEntry."BPC.Item No.") then begin
                    VATPostingSetup.Get(POSTransaction."Store No.", item."VAT Prod. Posting Group");
                    POSVAT.Get(VATPostingSetup."LSC POS Terminal VAT Code");
                    TransPaymentEntry."BPC.POS VAT Code" := POSVAT."VAT Code";
                    TransPaymentEntry."BPC.POS VAT%" := POSVAT."VAT %";
                    TransPaymentEntry."BPC.POS VAT Amount" := Round(TransPaymentEntry."Amount Tendered" * (POSVAT."VAT %" / (100 + POSVAT."VAT %")), 0.01);
                    TransPaymentEntry."BPC.POS VAT Excd. VAT" := TransPaymentEntry."Amount Tendered" - TransPaymentEntry."BPC.POS VAT Amount";
                end;
    end;

    //PostStmtJnlToFO PostStmtMovementToFO
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Statement-Post", 'OnAfterStatementPost', '', true, true)]
    local procedure OnAfterStatementPost(var Statement: Record "LSC Statement")
    var
        LocRetailSetup: Record "LSC Retail Setup";
        PostedStmt: Record "LSC Posted Statement";
        PostedStmt1: Record "LSC Posted Statement";
        InterfaceData: Codeunit "BPC.Interface Data";
        InsertStmtNotoItemLedEnt: Codeunit "BPC.InsertStmtNotoItemLedEnt";
        StmtNo: Code[20];
    // InterfaceDataCU: Codeunit "BPC.Interface Data";
    begin
        Clear(StmtNo);
        StmtNo := Statement."No.";
        LocRetailSetup.get();
        if StmtNo <> '' then begin
            PostedStmt1.Reset();
            PostedStmt1.SetRange("Pre-Assigned No.", StmtNo);
            if PostedStmt1.FindSet() then
                InsertStmtNotoItemLedEnt.Run(PostedStmt1);

            if LocRetailSetup."BPC.Interface D365 Active" then begin
                PostedStmt.Reset();
                PostedStmt.SetRange("Pre-Assigned No.", StmtNo);
                if PostedStmt.FindSet() then begin
                    InterfaceData.PostStmtJnlToFO(PostedStmt, false);
                    InterfaceData.PostStmtMovementToFO(PostedStmt, false);
                    PostedStmt."BPC Send To FO" := true;
                    PostedStmt.Modify();
                    //เสือ by พี่เซี้ยะ
                    // if InterfaceDataCU.ValidPostedStatementSalesQty(PostedStmt, false) then begin
                    //     InterfaceData.PostStmtJnlToFO(PostedStmt, false);
                    //     InterfaceData.PostStmtMovementToFO(PostedStmt, false);
                    //     PostedStmt."BPC Send To FO" := true;
                    //     PostedStmt.Modify();
                    // end;
                    //เสือ by พี่เซี้ยะ
                end;
            end;
        end;
    end;

    //Insert TMPItemLedgEntry
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', true, true)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    var
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
    begin
        RetailSetup.get();

        if RetailSetup."BPC.Interface D365 Active" then
            case ItemJournalLine."Entry Type" of
                "Item Ledger Entry Type"::"Negative Adjmt.":
                    if not TMPItemLedgEntry.Get(NewItemLedgEntry."Document No.", NewItemLedgEntry."Entry No.") then begin
                        TMPItemLedgEntry."Document No." := NewItemLedgEntry."Document No.";
                        TMPItemLedgEntry."Entry No." := NewItemLedgEntry."Entry No.";
                        TMPItemLedgEntry."Item No." := NewItemLedgEntry."Item No.";
                        TMPItemLedgEntry.Warehouse := NewItemLedgEntry."Location Code";
                        TMPItemLedgEntry."Reason Code" := ItemJournalLine."Reason Code";
                        TMPItemLedgEntry."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                        TMPItemLedgEntry."User ID" := CopyStr(UserId(), 1, 100);
                        TMPItemLedgEntry.Insert();
                    end;
                "Item Ledger Entry Type"::"Positive Adjmt.":
                    if not TMPItemLedgEntry.Get(NewItemLedgEntry."Document No.", NewItemLedgEntry."Entry No.") then begin
                        TMPItemLedgEntry."Document No." := NewItemLedgEntry."Document No.";
                        TMPItemLedgEntry."Entry No." := NewItemLedgEntry."Entry No.";
                        TMPItemLedgEntry."Item No." := NewItemLedgEntry."Item No.";
                        TMPItemLedgEntry.Warehouse := NewItemLedgEntry."Location Code";
                        TMPItemLedgEntry."Reason Code" := ItemJournalLine."Reason Code";
                        TMPItemLedgEntry."Entry Type" := NewItemLedgEntry."Entry Type"::"Positive Adjmt.";
                        TMPItemLedgEntry.QTY := NewItemLedgEntry.Quantity;
                        TMPItemLedgEntry."User ID" := CopyStr(UserId(), 1, 100);
                        TMPItemLedgEntry.Insert();
                    end;
                "Item Ledger Entry Type"::Transfer:
                    if not TMPItemLedgEntry.Get(NewItemLedgEntry."Document No.", NewItemLedgEntry."Entry No.") then begin
                        TMPItemLedgEntry."Document No." := NewItemLedgEntry."Document No.";
                        TMPItemLedgEntry."Entry No." := NewItemLedgEntry."Entry No.";
                        TMPItemLedgEntry."Item No." := NewItemLedgEntry."Item No.";
                        TMPItemLedgEntry.Warehouse := NewItemLedgEntry."Location Code";
                        TMPItemLedgEntry."BPC.Location code" := NewItemLedgEntry."Location Code";
                        TMPItemLedgEntry."BPC.New Location code" := ItemJournalLine."New Location Code";
                        TMPItemLedgEntry."Reason Code" := ItemJournalLine."Reason Code";
                        TMPItemLedgEntry."Entry Type" := ItemJournalLine."Entry Type"::Transfer;
                        TMPItemLedgEntry."User ID" := CopyStr(UserId(), 1, 100);
                        TMPItemLedgEntry.QTY := NewItemLedgEntry.Quantity;
                        TMPItemLedgEntry.Insert();
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', true, true)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    var
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
    begin
        TMPItemLedgEntry.SetRange("User ID", UserId);
        TMPItemLedgEntry.SetRange("Entry No.", ItemLedgerEntry."Entry No.");
        if TMPItemLedgEntry.FindSet() then begin
            TMPItemLedgEntry.QTY := ItemLedgerEntry.Quantity;
            TMPItemLedgEntry.Modify();
        end;

    end;

    //PostItemJournal ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC Store Inventory Management", 'OnAfterPostWorksheet', '', true, true)]
    local procedure BPCOnAfterPostWorksheet(var StoreInventoryWorksheet: Record "LSC Store Inventory Worksheet")
    var
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        Location: Record Location;
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        if not Location.Get(StoreInventoryWorksheet."Location Code") then
            Location.Init();
        RetailSetup.get();
        if (RetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then begin
            TMPItemLedgEntry.SetRange("User ID", UserId);
            TMPItemLedgEntry.SetFilter("Entry Type", '<>%1', TMPItemLedgEntry."Entry Type"::Transfer);
            if not TMPItemLedgEntry.IsEmpty() then
                InterfaceData.PostItemJournal(StoreInventoryWorksheet.WorksheetSeqNo);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", 'OnCodeOnAfterItemJnlPostBatchRun', '', true, true)]
    local procedure OnCodeOnAfterItemJnlPostBatchRun(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; SuppressCommit: Boolean)
    var
        LocRetailSetup: Record "LSC Retail Setup";
        Location: Record Location;
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        TMPItemLedgEntry.Reset();
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
        if not TMPItemLedgEntry.FindSet() then
            TMPItemLedgEntry.Init();

        if not Location.Get(TMPItemLedgEntry.Warehouse) then
            Location.Init();

        LocRetailSetup.get();
        if (LocRetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then
            case TMPItemLedgEntry."Entry Type" of
                TMPItemLedgEntry."Entry Type"::"Positive Adjmt.", TMPItemLedgEntry."Entry Type"::"Negative Adjmt.":
                    InterfaceData.PostItemJournals();
                TMPItemLedgEntry."Entry Type"::Transfer:
                    InterfaceData.PostTransferJournal();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", 'OnBeforeCode', '', true, true)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; SuppressCommit: Boolean)
    var
        ItemJournalLine_CheckPost: Record "Item Journal Line";
        DocumentNo: Code[20];
        LocationCode: Code[20];
        NewLocationCode: Code[20];
        N: Integer;
        Item: Page "Item Reclass. Journal";
    begin
        N := 0;
        DocumentNo := '';
        LocationCode := '';
        NewLocationCode := '';
        ItemJournalLine_CheckPost.Reset();
        ItemJournalLine_CheckPost.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine_CheckPost.SetRange("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        ItemJournalLine_CheckPost.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        if ItemJournalLine_CheckPost.FindSet() then begin
            repeat
                if N <> 0 then begin
                    if ItemJournalLine_CheckPost."Document No." <> DocumentNo then begin
                        DocumentNo := ItemJournalLine_CheckPost."Document No.";
                        Error('You can select document no. only one entry');
                    end;
                    if ItemJournalLine_CheckPost."Location Code" <> LocationCode then begin
                        LocationCode := ItemJournalLine_CheckPost."Location Code";
                        Error('You can select location code only one entry');
                    end;
                    if ItemJournalLine_CheckPost."New Location Code" <> NewLocationCode then begin
                        NewLocationCode := ItemJournalLine_CheckPost."New Location Code";
                        Error('You can select new location code only one entry');
                    end;
                end else begin
                    DocumentNo := ItemJournalLine_CheckPost."Document No.";
                    LocationCode := ItemJournalLine_CheckPost."Location Code";
                    NewLocationCode := ItemJournalLine_CheckPost."New Location Code";
                end;
                N += 1;
            until ItemJournalLine_CheckPost.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post+Print", 'OnBeforePostJournalBatch', '', true, true)]
    local procedure OnBeforePostJournalBatch(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    var
        ItemJournalLine_CheckPost: Record "Item Journal Line";
        DocumentNo: Code[20];
        LocationCode: Code[20];
        NewLocationCode: Code[20];
        N: Integer;
        Item: Page "Item Reclass. Journal";
    begin
        N := 0;
        DocumentNo := '';
        LocationCode := '';
        NewLocationCode := '';
        ItemJournalLine_CheckPost.Reset();
        ItemJournalLine_CheckPost.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine_CheckPost.SetRange("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        ItemJournalLine_CheckPost.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        if ItemJournalLine_CheckPost.FindSet() then begin
            repeat
                if N <> 0 then begin
                    if ItemJournalLine_CheckPost."Document No." <> DocumentNo then begin
                        DocumentNo := ItemJournalLine_CheckPost."Document No.";
                        Error('You can select document no. only one entry');
                    end;
                    if ItemJournalLine_CheckPost."Location Code" <> LocationCode then begin
                        LocationCode := ItemJournalLine_CheckPost."Location Code";
                        Error('You can select location code only one entry');
                    end;
                    if ItemJournalLine_CheckPost."New Location Code" <> NewLocationCode then begin
                        NewLocationCode := ItemJournalLine_CheckPost."New Location Code";
                        Error('You can select new location code only one entry');
                    end;
                end else begin
                    DocumentNo := ItemJournalLine_CheckPost."Document No.";
                    LocationCode := ItemJournalLine_CheckPost."Location Code";
                    NewLocationCode := ItemJournalLine_CheckPost."New Location Code";
                end;
                N += 1;
            until ItemJournalLine_CheckPost.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post+Print", 'OnAfterPostJournalBatch', '', true, true)]
    local procedure OnAfterPostJournalBatch(var ItemJournalLine: Record "Item Journal Line");
    var
        LocRetailSetup: Record "LSC Retail Setup";
        Location: Record Location;
        TMPItemLedgEntry: Record "BPC.TMPItemLedgEntry";
        InterfaceData: Codeunit "BPC.Interface Data";
    begin
        TMPItemLedgEntry.Reset();
        TMPItemLedgEntry.SetRange(TMPItemLedgEntry."User ID", UserId);
        if not TMPItemLedgEntry.FindSet() then
            TMPItemLedgEntry.Init();

        if not Location.Get(TMPItemLedgEntry.Warehouse) then
            Location.Init();

        LocRetailSetup.get();
        if (LocRetailSetup."BPC.Interface D365 Active") and (not Location."BPC.Not sent to FO") then
            case TMPItemLedgEntry."Entry Type" of
                TMPItemLedgEntry."Entry Type"::"Positive Adjmt.", TMPItemLedgEntry."Entry Type"::"Negative Adjmt.":
                    InterfaceData.PostItemJournals();
                TMPItemLedgEntry."Entry Type"::Transfer:
                    InterfaceData.PostTransferJournal();
            end;
    end;
    //PostItemJournal --

    //NoAutoAsmToOrder
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnValidateQtyToAssembleToOrderOnBeforeAutoAsmToOrder', '', true, true)]
    local procedure OnValidateQtyToAssembleToOrderOnBeforeAutoAsmToOrder(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        if SalesLine."BPC.Not Check AutoAsmToOrder" = true then
            IsHandled := true;
    end;
    //เก็บ Sales Order No. ลง Transaction Header ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeGetOrder', '', true, true)]
    local procedure OnBeforeGetOrder(var LSCPosTransaction: Record "LSC POS Transaction"; DocType: Enum "Sales Document Type"; DocNumber: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LSCPosTransaction."BPC.Sales Order No." := DocNumber;
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", DocNumber);
        if not SalesHeader.IsEmpty() then begin
            LSCPosTransaction."BPC.Reference Online Order" := SalesHeader."BPC.Reference Online Order";
            LSCPosTransaction."BPC.Sales Order Posting Date" := SalesHeader."Posting Date";
            LSCPosTransaction."BPC.Sales Order Document Date" := SalesHeader."Document Date";
            LSCPosTransaction."BPC.Bill-to Address" := SalesHeader."Bill-to Address";
            LSCPosTransaction."BPC.Bill-to Address 2" := SalesHeader."Bill-to Address 2";
            LSCPosTransaction."BPC.Bill-to City" := SalesHeader."Bill-to City";
            LSCPosTransaction."BPC.Bill-to County" := SalesHeader."Bill-to Country/Region Code";
            LSCPosTransaction."BPC.Bill-to Post Code" := SalesHeader."Bill-to Post Code";
            LSCPosTransaction."BPC.Bill-to Name" := SalesHeader."Bill-to Name";
            LSCPosTransaction."BPC.Interface" := SalesHeader."BPC.Interface";
        end;
        LSCPosTransaction.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnAfterInsertTransHeader', '', true, true)]
    local procedure OnAfterInsertTransHeader(var Transaction: Record "LSC Transaction Header"; var POSTrans: Record "LSC POS Transaction")
    begin
        Transaction."BPC.Sales Order No." := POSTrans."BPC.Sales Order No.";

        Transaction."BPC.Reference Online Order" := POSTrans."BPC.Reference Online Order";
        Transaction."BPC.Sales Order Posting Date" := POSTrans."BPC.Sales Order Posting Date";
        Transaction."BPC.Sales Order Document Date" := POSTrans."BPC.Sales Order Document Date";
        Transaction."BPC.Sales Order Document Date" := POSTrans."BPC.Sales Order Document Date";
        // if POSTrans."BPC.Sales Order No." <> '' then begin
        //     Transaction.cu :=  POSTrans."BPC.Bill-to Address";
        //     Transaction."BPC.Bill-to Address 2" := POSTrans."BPC.Bill-to Address 2";
        //     Transaction."BPC.Bill-to City" := POSTrans."BPC.Bill-to City";
        //     Transaction."BPC.Bill-to County" := POSTrans."BPC.Bill-to County";
        //     Transaction."BPC.Bill-to Post Code" := POSTrans."BPC.Bill-to Post Code";
        //     Transaction."BPC.Bill-to Name" := POSTrans."BPC.Bill-to Name";
        // end;
    end;
    //เก็บ Sales Order No. ลง Transaction Header --

    //ถ้าGet Order ผ่าน API ไม่ต้องเช็คส่วนลด โปรโมชัน ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Price Utility", 'OnBeforeRegisterPeriodicDisc', '', true, true)]
    local procedure OnBeforeRegisterPeriodicDisc(var Currline: Record "LSC POS Trans. Line"; var TmpPeriodicDiscount: Record "LSC Periodic Discount" temporary; var IsHandled: Boolean)
    begin
        if Currline."BPC.Interface" then
            IsHandled := true;
    end;
    //ถ้าGet Order ผ่าน API ไม่ต้องเช็คส่วนลด โปรโมชัน --

    //ถ้าGet Order ผ่าน API ไม่ต้องเช็คส่วนลด Total ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Offer Ext. Utility", 'OnCalcTotalOfferOnAfterFindLastPeriodicDiscBenefits', '', true, true)]
    local procedure OnCalcTotalOfferOnAfterFindLastPeriodicDiscBenefits(var PeriodicDiscBenefits: Record "LSC Periodic Discount Benefits"; var pPosTrans: Record "LSC POS Transaction"; var pOffersTemp: Record "LSC Periodic Discount" temporary; var IsHandled: Boolean; PeriodicDiscount: Record "LSC Periodic Discount"; pTotalAmount: Decimal)
    begin
        if pPosTrans."BPC.Interface" then
            IsHandled := true;
    end;
    //ถ้าGet Order ผ่าน API ไม่ต้องเช็คส่วนลด Total --

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Order Connection", 'OnBeforePOSTransLineInsertInGetSHSL', '', true, true)]
    local procedure OnBeforePOSTransLineInsertInGetSHSL(var PosTransaction: Record "LSC POS Transaction"; var PosTransLine: Record "LSC POS Trans. Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        PosTransLine."BPC.Order No." := SalesLine."Document No.";
        PosTransLine."BPC.Order Line No." := SalesLine."Line No.";
        PosTransLine."BPC.Inv. Discount Amount" := SalesLine."Inv. Discount Amount";
        PosTransLine."BPC.Location Code" := SalesLine."Location Code";
        PosTransLine."BPC.Interface" := SalesLine."BPC.Interface";
        PosTransLine."BPC.Bill-to Address" := SalesHeader."Bill-to Address";
        PosTransLine."BPC.Bill-to Address 2" := SalesHeader."Bill-to Address 2";
        PosTransLine."BPC.Bill-to City" := SalesHeader."Bill-to City";
        PosTransLine."BPC.Bill-to County" := SalesHeader."Bill-to Country/Region Code";
        PosTransLine."BPC.Bill-to Post Code" := SalesHeader."Bill-to Post Code";
        PosTransLine."BPC.Bill-to Name" := SalesHeader."Bill-to Name";
        PosTransLine."BPC.VAT Registration No." := SalesHeader."VAT Registration No.";
    end;

    //ลบ Sales Order แล้วสร้าง PostedCustOrder ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnBeforeProcessTransaction', '', true, true)]
    local procedure OnBeforeProcessTransaction(var PosTrans: Record "LSC POS Transaction"; var TransSalesTaxEntryTEMP: Record "LSC Trans. SalesTax Entry" temporary)
    var
        POSTransLine: Record "LSC POS Trans. Line";
        PostedCustOrder: Record "LSC Posted CO Header";
        PostedCustOrderLine: Record "LSC Posted Customer Order Line";
        Customer: Record Customer;
        ItemVariant: Record "Item Variant";
    begin
        if (PosTrans."Document No." <> '') and (PosTrans."Entry Status" <> PosTrans."Entry Status"::Voided) then begin
            POSTransLine.Reset();
            POSTransLine.SetRange("Receipt No.", PosTrans."Receipt No.");
            POSTransLine.SetRange("Entry Status", POSTransLine."Entry Status"::" ");
            POSTransLine.SetFilter("BPC.Order No.", '<>%1', '');
            POSTransLine.SetFilter("BPC.Order Line No.", '<>%1', 0);
            if POSTransLine.FindSet() then
                repeat
                    UpdateSLandOrderLine(POSTransLine."BPC.Order No.", POSTransLine."BPC.Order Line No.");
                    if not PostedCustOrder.Get(POSTransLine."BPC.Order No.") then begin
                        PostedCustOrder.Init();
                        PostedCustOrder."Document ID" := POSTransLine."BPC.Order No.";
#pragma warning disable AL0432
                        PostedCustOrder."Store No." := POSTransLine."Store No.";
#pragma warning restore AL0432
                        PostedCustOrder."BPC.Collect Location" := POSTransLine."BPC.Location Code";
                        PostedCustOrder."BPC.Document DateTime" := CurrentDateTime();
#pragma warning disable AL0432
                        PostedCustOrder.Status := PostedCustOrder.Status::Finish;
#pragma warning restore AL0432
                        PostedCustOrder."BPC.Currency Factor" := 1;
                        PostedCustOrder."BPC.Vat Bus. Posting Group" := PosTrans."VAT Bus.Posting Group";
                        PostedCustOrder."Customer No." := PosTrans."Customer No.";
                        PostedCustOrder."Member Card No." := PosTrans."Member Card No.";
#pragma warning disable AL0432
                        PostedCustOrder."Collect Time Limit" := CurrentDateTime();
#pragma warning restore AL0432
                        PostedCustOrder.Created := CurrentDateTime();
                        PostedCustOrder."BPC.Receipt No." := POSTransLine."Receipt No.";
                        PostedCustOrder."BPC.Trans. Store No." := POSTransLine."Store No.";
                        PostedCustOrder."BPC.Trans. Terminal No." := POSTransLine."POS Terminal No.";

                        PostedCustOrder."BPC.Bill-to Address" := PosTransLine."BPC.Bill-to Address";
                        PostedCustOrder."BPC.Bill-to Address 2" := PosTransLine."BPC.Bill-to Address 2";
                        PostedCustOrder."BPC.Bill-to City" := PosTransLine."BPC.Bill-to City";
                        PostedCustOrder."BPC.Bill-to County" := PosTransLine."BPC.Bill-to County";
                        PostedCustOrder."BPC.Bill-to Post Code" := PosTransLine."BPC.Bill-to Post Code";
                        PostedCustOrder."BPC.Bill-to Name" := PosTransLine."BPC.Bill-to Name";
                        PostedCustOrder."BPC.VAT Registration No." := PosTransLine."BPC.VAT Registration No.";
                        if Customer.Get(PosTrans."Customer No.") then
                            PostedCustOrder."BPC.Full Name" := Customer.Name;
                        PostedCustOrder.Insert();
                    end;
                    PostedCustOrderLine.Init();
                    PostedCustOrderLine."Document ID" := POSTransLine."BPC.Order No.";
                    PostedCustOrderLine."Line No." := POSTransLine."BPC.Order Line No.";
                    PostedCustOrderLine.Status := PostedCustOrderLine.Status::Collected;
                    PostedCustOrderLine."Line Type" := PostedCustOrderLine."Line Type"::Item;
                    PostedCustOrderLine.Number := POSTransLine.Number;
                    PostedCustOrderLine."Variant Code" := POSTransLine."Variant Code";
                    PostedCustOrderLine."Unit of Measure Code" := POSTransLine."Unit of Measure";
                    PostedCustOrderLine."Net Price" := POSTransLine."Net Price";
                    PostedCustOrderLine.Price := POSTransLine.Price;
                    PostedCustOrderLine.Quantity := POSTransLine.Quantity;
                    PostedCustOrderLine."Discount Amount" := POSTransLine."Discount Amount";
                    PostedCustOrderLine."Discount Percent" := POSTransLine."Discount %";
                    PostedCustOrderLine."Net Amount" := POSTransLine."Net Amount";
                    PostedCustOrderLine."Vat Amount" := POSTransLine."VAT Amount";
                    PostedCustOrderLine.Amount := POSTransLine.Amount;
                    PostedCustOrderLine."Item Description" := POSTransLine.Description;
                    if not ItemVariant.Get(POSTransLine.Number, POSTransLine."Variant Code") then
                        ItemVariant.Init();
                    PostedCustOrderLine."Variant Description" := ItemVariant.Description;
                    PostedCustOrderLine."Unit of Measure Code" := POSTransLine."Unit of Measure";
                    PostedCustOrderLine."Original Line No." := POSTransLine."Line No.";
                    PostedCustOrderLine.Insert();
                UNTIL POSTransLine.Next() = 0;
            PosTrans."Document No." := '';
        end;
    end;
    //ลบ Sales Order แล้วสร้าง PostedCustOrder --

    //PostSalesShipment หน้า่ POS ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", 'OnAfterPostTransaction', '', true, true)]
    local procedure OnAfterPostTransaction(var TransactionHeader_p: Record "LSC Transaction Header")
    var
        LSCTenderTypeSetup: Record "LSC Tender Type Setup";
        LocRetailSetup: Record "LSC Retail Setup";
        TenderTypeEntry: Record "BPC Tender Type Entry";
        InterfacePOS: Codeunit "BPC.Interface POS";
        TenderType: Code[10];
    begin
        LocRetailSetup.Get();
        Clear(TenderType);
        TenderTypeEntry.Reset();
        TenderTypeEntry.SetRange("BPC Receipt No.", TransactionHeader_p."Receipt No.");
        if TenderTypeEntry.FindLast() then
            TenderType := TenderTypeEntry."BPC Tender Type";

        if not LSCTenderTypeSetup.Get(TenderType) then
            LSCTenderTypeSetup.Init();

        if LSCTenderTypeSetup."BPC.Platform" then //begin
            //RetailSetup.TestField("bpc.Interface D365 Active"); //--A-- 2024/03/11 Assign-37
            if TransactionHeader_p."BPC.Sales Order No." <> '' then
                InterfacePOS.PostSalesShipment_POS(TransactionHeader_p);
        //end;
    end;
    //PostSalesShipment หน้า่ POS --

    //GetSalesHeader หน้า POS ++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommand', '', true, true)]
    local procedure OnBeforeRunCommand(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var POSMenuLine: Record "LSC POS Menu Line"; var isHandled: Boolean; TenderType: Record "LSC Tender Type"; var CusomterOrCardNo: Code[20])
    var
        LocRetailSetup: Record "LSC Retail Setup";
        POSTrantion: Codeunit "LSC POS Transaction";
    // InterfacePOS: Codeunit "BPC.Interface POS";
    begin
        LocRetailSetup.Get();
        if (POSMenuLine.Command = 'LOOKUP') and (POSTransLine."BPC.Order No." <> '') and (POSTransLine."BPC.Interface") then begin
            POSTrantion.ErrorBeep('ไม่สามารถเพิ่ม Item ได้');
            isHandled := true;
        end;

        if (POSMenuLine.Command = 'ITEMNO') and (POSTransLine."BPC.Order No." <> '') and (POSTransLine."BPC.Interface") then begin
            POSTrantion.ErrorBeep('ไม่สามารถเพิ่ม Item ได้');
            isHandled := true;
        end;
        if (POSMenuLine.Command = 'QTYCH') and (POSTransLine."BPC.Order No." <> '') and (POSTransLine."BPC.Interface") then begin
            POSTrantion.ErrorBeep('ไม่สามารถแก้ไขปริมาณได้');
            isHandled := true;
        end;
        if (POSMenuLine.Command = 'LINE_DISC_OFFER') and (POSTransLine."BPC.Order No." <> '') and (POSTransLine."BPC.Interface") then begin
            POSTrantion.ErrorBeep('ไม่สามารถแก้ไขจำนวนส่วนลดได้');
            isHandled := true;
        end;

        // if (RetailSetup."BPC.Interface D365 Active") and (POSMenuLine.Command = 'GETORDER') then
        //     InterfacePOS.GetSalesHeader_POS();
    end;
    //GetSalesHeader หน้า POS --

    //ส่วนลดท้ายบิล SO POS ++
    // [EventSubscriber(ObjectType::Table, database::"LSC POS Trans. Line", 'OnAfterCalcPrices', '', true, true)]
    // local procedure OnAfterCalcPrices(var Rec: Record "LSC POS Trans. Line")
    // var
    //     "Disc%": Decimal;
    //     SalesLine: Record "Sales Line";
    //     DiscAmt: Decimal;
    // begin
    //     Clear("Disc%");
    //     if (Rec."BPC.Order No." <> '') and (rec."BPC.Inv. Discount Amount" <> 0) then begin
    //         SalesLine.Reset();
    //         SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
    //         SalesLine.SetRange("Document No.", Rec."BPC.Order No.");
    //         SalesLine.SetRange("Line No.", Rec."BPC.Order Line No.");
    //         if SalesLine.FindSet() then begin
    //             "Disc%" := ((SalesLine."Line Discount Amount" * 100) / (SalesLine."Unit Price" * SalesLine.Quantity)) + ((SalesLine."Inv. Discount Amount" * 100) / (SalesLine."Unit Price" * SalesLine.Quantity));
    //             if rec."Discount %" <> "Disc%" then begin
    //                 rec."Discount %" := "Disc%";
    //                 rec."Line Disc. %" := "Disc%";
    //                 DiscAmt := rec.Price * rec.Quantity;
    //                 DiscAmt := DiscAmt * ("Disc%" / 100);
    //                 rec."Discount Amount" := ROUND(DiscAmt, 0.001, '=');

    //                 rec.Amount := (rec.Price * rec.Quantity) - rec."Discount Amount";
    //                 rec."Net Amount" := rec.Amount / (1 + (rec."VAT %" / 100));
    //                 rec."VAT Amount" := rec.Amount - rec."Net Amount";
    //                 rec."Cost Amount" := rec."Cost Price" * rec.Quantity;
    //             end;
    //         end;
    //     end;
    // end;
    //ส่วนลดท้ายบิล SO POS --

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterValidateDisc', '', true, true)]
    local procedure OnAfterValidateDisc(var LineRec: Record "LSC POS Trans. Line"; var IsHandled: Boolean)
    var
        POSTransaction: Codeunit "LSC POS Transaction";
    begin
        if LineRec."BPC.Interface" then begin
            IsHandled := true;
            POSTransaction.ErrorBeep('ไม่สามารถแก้ไขจำนวนส่วนลดได้');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforeSalesLineFind', '', true, true)]
    local procedure OnBeforeSalesLineFind(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean; var IsHandled: Boolean)
    begin
        if SalesHeader."BPC.Interface" = true then
            IsHandled := true;

    end;

    //--A-- 2024/01/29
    //เพิ่ม Customer ที่บันทัดสุดท้ายของ line หลัง Get Order Online >> POS
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnGetOrderPressedAfterInfoTextDescription', '', true, true)]
    local procedure OnGetOrderPressedAfterInfoTextDescription(var CurrInput: Text; var POSTransaction: Record "LSC POS Transaction"; var DocType: Enum "Sales Document Type"; var OrderNo: Code[20])
    var
        xPostransLine: Record "LSC POS Trans. Line";
        SalesHeader: Record "Sales Header";
        LastLineNo: Integer;
    begin
        if SalesHeader.get(DocType, OrderNo) then begin
            xPostransLine.Reset();
            xPostransLine.SetRange("Receipt No.", POSTransaction."Receipt No.");
            if xPostransLine.FindLast() then
                LastLineNo := xPostransLine."Line No.";
            LastLineNo += 10000;

            xPostransLine.Init();
            xPostransLine."Receipt No." := POSTransaction."Receipt No.";
            xPostransLine."Line No." := LastLineNo;
            xPostransLine.Insert();

            xPostransLine."Entry Type" := xPostransLine."Entry Type"::FreeText;
            xPostransLine.Description := CopyStr('Cust:' + SalesHeader."Sell-to Customer Name", 1, 100);
            xPostransLine."Store No." := POSTransaction."Store No.";
            xPostransLine."POS Terminal No." := POSTransaction."POS Terminal No.";
            xPostransLine."Text Type" := xPostransLine."Text Type"::"Cust. Text";
            xPostransLine."Card/Customer/Coup.Item No" := SalesHeader."Sell-to Customer No.";
            xPostransLine."Trans. Date" := Today();
            xPostransLine."Trans. Time" := Time();
            xPostransLine.Counter := 1;
            xPostransLine.Modify();
        end;
    end;
    //--A-- 2024/01/29

    // Joe: Copy Brand from Item 2025/05/29 ++
    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", OnAfterCopyFromItem, '', true, true)]
    local procedure OnAfterCopyFromItem(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
        StockkeepingUnit."BPC.Brand" := Item."BPC.Brand";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Stockkeeping Unit", OnBeforeStockkeepingUnitInsert, '', true, true)]
    local procedure OnBeforeStockkeepingUnitInsert(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
        StockkeepingUnit."BPC.Brand" := Item."BPC.Brand";
    end;
    // Joe: Copy Brand from Item 2025/05/29 --

    // // Change POS customer name from online sales order
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterGetContext, '', true, true)]
    // local procedure OnAfterGetContext(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text)
    // var
    //     Customer: Record Customer;
    //     SalesHeader: Record "Sales Header";
    //     POSSESSION: Codeunit "LSC POS Session";
    // begin
    //     if POSTransaction."Document No." <> '' then
    //         if SalesHeader.Get(SalesHeader."Document Type"::Order, POSTransaction."Document No.") then
    //             if POSTransaction."Customer No." <> '' then begin
    //                 Customer.SetRange("No.", POSTransaction."Customer No.");
    //                 Customer.SetRange("BPC.API Not Update Customer", true);
    //                 if not Customer.IsEmpty() then
    //                     POSSESSION.SetValue("LSC POS Tag"::"CustomerName", SalesHeader."Sell-to Customer Name");
    //             end;
    // end;

    // // Show POS Customer Name from Sell-to Customer Name Joe 2025-04-04 ++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Order Connection", OnBeforePostransactionModifyInGetSHSL, '', true, true)]
    // local procedure OnBeforePostransactionModifyInGetSHSL(var pPosTransaction: Record "LSC POS Transaction"; pSalesHeader: Record "Sales Header")
    // var
    //     POSSESSION: Codeunit "LSC POS Session";
    // begin
    //     POSSESSION.SetValue('SellToCustomerName', pSalesHeader."Sell-to Customer Name");
    // end;
    // // Show POS Customer Name from Sell-to Customer Name Joe 2025-04-04 --

    // // Clear POS Sell-to Customer Name Joe 2025-04-04 ++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction", OnAfterClearGlobs, '', true, true)]
    // local procedure OnAfterClearGlobs()
    // var
    //     POSSESSION: Codeunit "LSC POS Session";
    // begin
    //     POSSESSION.SetValue('SellToCustomerName', '');
    // end;
    // // Clear POS Sell-to Customer Name Joe 2025-04-04 --

    procedure UpdateSLandOrderLine(pOrderNo: Code[20]; pOrderLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        CustOrderLine: Record "LSC Customer Order Line";
    begin
        if SalesLine.Get(SalesLine."Document Type"::Order, pOrderNo, pOrderLineNo) then
            SalesLine.Delete();

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", pOrderNo);
        if SalesLine.IsEmpty() then
            if SalesHeader.Get(SalesHeader."Document Type"::Order, pOrderNo) then
                SalesHeader.Delete();

        if CustOrderLine.Get(pOrderNo, pOrderLineNo) then begin
            CustOrderLine.Status := CustOrderLine.Status::Collected;
            CustOrderLine.Modify();
        end;
    end;

    var
        RetailSetup: Record "LSC Retail Setup";
        LSGRNNo: Code[20];
}