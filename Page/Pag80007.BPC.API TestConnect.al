page 80007 "BPC.API.TestConnectSet"
{
    PageType = API;
    Caption = 'apiTestConnectSet';
    APIPublisher = 'bpc';
    APIGroup = 'apiBIG';
    APIVersion = 'v2.0';
    EntityName = 'testconnect';
    EntitySetName = 'testconnects';
    SourceTable = "Sales Header";
    DelayedInsert = true;
    DeleteAllowed = false;
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupConnect)
            {
                field(id; rec.SystemId)
                {
                    Caption = 'id';
                    Editable = false;
                }
                field(pTestConnect; pTestConnect)
                {
                    Caption = 'pTestConnect';
                    trigger OnValidate()
                    begin
                        pTestConnect := FuncTestConnect;
                    end;
                }
            }
        }
    }

    local procedure FuncTestConnect(): Text
    begin
        EXIT(STRSUBSTNO('%1 : Connect Success.', pTestConnect));
    end;

    var
        pTestConnect: Text;
}