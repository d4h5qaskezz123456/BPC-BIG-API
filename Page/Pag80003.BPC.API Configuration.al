page 80003 "BPC.API Configuration"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BPC.API Configuration";
    Editable = true;
    DeleteAllowed = false;
    Caption = 'API Configuration';

    layout
    {
        area(Content)
        {
            group(URL)
            {
                field("GetPurchaseHeader"; Rec."GetPurchaseHeader")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("GetPurchaseLine"; Rec."GetPurchaseLine")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("GetSalesHeader"; Rec."GetSalesHeader")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("GetSalesLine"; Rec."GetSalesLine")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("GetTransferHeader"; Rec."GetTransferHeader")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("GetTransferLine"; Rec."GetTransferLine")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostPurchaseReceive"; Rec."PostPurchaseReceive")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendPurchaseReceive"; Rec."SendPurchaseReceive")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendUndoReceipt"; Rec."SendUndoReceipt")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostPurchaseShipment"; Rec."PostPurchaseShipment")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostTransfersShipment"; Rec."PostTransfersShipment")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostTransfersReceipt"; Rec."PostTransfersReceipt")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendCheckSerial"; Rec."SendCheckSerial")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("CheckSerialExist"; Rec."CheckSerialExist")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendCloseBill"; Rec."SendCloseBill")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendVoidBill"; Rec."SendVoidBill")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendChkInvenLookupInStock"; Rec."SendChkInvenLookupInStock")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostTransferJournal"; Rec."PostTransferJournal")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostInventCountingJournal"; Rec."PostInventCountingJournal")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostInventAdjustJournal"; Rec."PostInventAdjustJournal")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("APITestConnection"; Rec."APITestConnection")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("postStmtJournal"; Rec."postStmtJournal")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("postStmtMovement"; Rec."postStmtMovement")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("getStmtStatus"; Rec."getStmtStatus")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("getGRNStatus"; Rec."getGRNStatus")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("getInventTrans"; Rec."getInventTrans")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostSalesShipment"; Rec."PostSalesShipment")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendCheckStock"; Rec."SendCheckStock")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("CreateProduct"; Rec."CreateProduct")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostTransfersReceiptAuto"; Rec."PostTransfersReceiptAuto")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendExpense"; Rec."SendExpense")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("PostItemJournal"; Rec."PostItemJournal")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("SendUndoShipment"; Rec."SendUndoShipment")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }

            }
            group("GET Item")
            {
                field("GetItem"; Rec."GetItem")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field(StarDate; Rec.StarDate)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field(EndDate; Rec.EndDate)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }

            }
        }
    }
    actions
    {

    }

}