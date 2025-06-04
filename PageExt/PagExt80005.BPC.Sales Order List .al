pageextension 80005 "BPC.Sales Order List " extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {

        addafter("&Print")
        {

        }

        //NM Test
        addafter("Order &Promising")
        {
            action(TestAPIMember)
            {
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                var
                    BPCTempMemberConTact: Record "BPC.TMP Member Contact" temporary;
                begin
                    BPCTempMemberConTact.Init();
                    BPCTempMemberConTact."BPC Account No." := 'T002124';
                    BPCTempMemberConTact."BPC Name" := 'บริษัท พานาโซนิค โซลูชั่นส์ (ประเทศไทย) จำกัด บริษัท พานาโซนิค โซลูชั่นส์ (ประเทศไทย) จำกัด บริษัท พานาโซนิค โซลูชั่นส์ (ประเทศไทย) กฟกดกกกพำหหกำพกฟกดกำกกำพำ';
                    BPCTempMemberConTact."BPC Address" := '229/95 หมู่ที่ 12 ตำบลหนองปรือ อำเภอบางละมุง จังหวัดชลบุรี 20150 229/95 หมู่ที่ 12 ตำบลหนองปรือ อำเภอบางละมุง จังหวัดชลบุรี 20150 ตำบลหนองปรือ อำเภอบางละมุง';
                    BPCTempMemberConTact."BPC City" := 'หนองคาย';
                    BPCTempMemberConTact."BPC Post Code" := '43120';
                    BPCTempMemberConTact."BPC VAT Registration No." := '1234567891234';
                    BPCTempMemberConTact."BPC Mobile Phone No." := '022349821';
                    BPCTempMemberConTact."BPC Phone No." := '0623683883';
                    BPCTempMemberConTact."BPC E-Mail" := 'ff@gmail.com';
                    BPCTempMemberConTact."BPC Date of Birth" := '10/02/1996';
                    // BPCTempMemberConTact."BPC Gender" := '';
                    BPCTempMemberConTact.Insert(true);

                    Codeunit.Run(Codeunit::"BPC.Insert Member", BPCTempMemberConTact);
                end;
            }
        }
        //NM Test

    }



    var
        InterfaceData: Codeunit "BPC.Interface Data";
}