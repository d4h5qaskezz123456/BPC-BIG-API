table 80005 "BPC.API Configuration"
{
    Caption = 'API Configuration';

    fields
    {
        field(80000; "GetPurchaseHeader"; text[200])
        {

        }
        field(80001; "GetPurchaseLine"; text[200])
        {

        }
        field(80002; "GetSalesHeader"; text[200])
        {

        }
        field(80003; "GetSalesLine"; text[200])
        {

        }
        field(80004; "GetTransferHeader"; text[200])
        {

        }
        field(80005; "GetTransferLine"; text[200])
        {

        }
        field(80006; "PostPurchaseReceive"; text[200])
        {

        }
        field(80007; "SendPurchaseReceive"; text[200])
        {

        }
        field(80008; "SendUndoReceipt"; text[200])
        {

        }
        field(80009; "PostPurchaseShipment"; text[200])
        {

        }
        field(80010; "PostTransfersShipment"; text[200])
        {

        }
        field(80011; "PostTransfersReceipt"; text[200])
        {

        }
        field(80012; "SendCheckSerial"; text[200])
        {

        }
        field(80013; "CheckSerialExist"; text[200])
        {

        }
        field(80014; "SendCloseBill"; text[200])
        {

        }
        field(80015; "SendVoidBill"; text[200])
        {

        }
        field(80016; "SendChkInvenLookupInStock"; text[200])
        {

        }
        field(80017; "PostTransferJournal"; text[200])
        {

        }
        field(80018; "PostInventCountingJournal"; text[200])
        {

        }
        field(80019; "PostInventAdjustJournal"; text[200])
        {

        }
        field(80020; "APITestConnection"; text[200])
        {

        }
        field(80021; "postStmtJournal"; text[200])
        {

        }
        field(80022; "postStmtMovement"; text[200])
        {

        }
        field(80023; "getStmtStatus"; text[200])
        {

        }
        field(80024; "getGRNStatus"; text[200])
        {

        }
        field(80025; "getInventTrans"; text[200])
        {

        }
        field(80026; "PostSalesShipment"; text[200])
        {
        }
        field(80027; "SendCheckStock"; text[200])
        {
        }
        field(80028; "CreateProduct"; text[200])
        {
        }
        field(80029; "PostTransfersReceiptAuto"; text[200])
        {
        }
        field(80030; "SendExpense"; text[200])
        {
        }
        field(80032; "GetItem"; text[200])
        {
        }
        field(80033; "Key"; Code[20])
        {

        }
        field(80034; "StarDate"; DateTime)
        {
        }
        field(80035; "EndDate"; DateTime)
        {
        }
        field(80036; "PostItemJournal"; text[200])
        {
        }
        field(80037; "SendUndoShipment"; text[200])
        {
        }

    }
    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

}

