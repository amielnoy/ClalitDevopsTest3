# ClalitDevopsTest

4. Create these components by only azurerm 

·                  - Resourcegroup

·                  - VNET

·                  - DiagnosticsService

·                  - Storage account

·                  -  Function App


5.Create Private Endpoint to the Function App using subnet and vnet by using only terraform

6.create Private Endpoint for the storage Account and connect it to the Subnet in the Vnet you created.

7.Define access between the Function app and storage account using Managed Identity 

8.Import the resources you deployed using Output

 For creating the required resources on azure cloud account:
 on the cmd :
 1.az login & complete the login to azure account
 2.git clone https://github.com/amielnoy/ClalitDevopsTest3
 3.terraform init
 4.terraform plan
 5.terraform apply
 
 running the terraform SOLUTION:

 1.login to the azure cli 
   using az login
   
 2.git clone  https://github.com/amielnoy/ClalitDevopsTest3.git
 
 3.on a teminal go to the root of the project
 & run: terraform init
 
 4.run terraform apply
