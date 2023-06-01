    echo  "######" | az devops login --organization https://dev.azure.com/contoso/
    
    X001680@aldi-nord.com
    douhkd#cprPeo9we
    

    
    MY_PAT=fnncrw7lyiknfpqmv5wrr7bbahvmzo3oszukms3bdstvymko6kha
    B64_PAT=$(printf "%s"":$MY_PAT" | base64)
    git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-DevOps-ControlRepo/_git/AN-Azure-DevOps-ControlRepo-non-SAP -b main
    cd AN-Azure-DevOps-ControlRepo-non-SAP
    ls -latr
    echo "Something"
    cd ../
    git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-TestProject-ControlRepo/_git/AN-Azure-TestProject-ControlRepo
    cd AN-Azure-TestProject-ControlRepo
    ls -latr
    cd ../AN-Azure-DevOps-ControlRepo-non-SAP
    cp -R .docs README.md ../AN-Azure-TestProject-ControlRepo
    ls -latr
    echo "Testing"
    pwd
    cd ../AN-Azure-TestProject-ControlRepo
    git add .
    git status
    echo "Something12"
    pwd
    git branch
    git config --global user.email "X001680@aldi-nord.com"
    git config --global user.name "Karnan Kali"
    git remote add origin https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-TestProject-ControlRepo/_git/AN-Azure-TestProject-ControlRepo
    git commit -m "added base files" --no-verify
    #git push
    git status
    cd ../AN-Azure-TestProject-ControlRepo
    ls -ltra



az devops configure --defaults organization=https://dev.azure.com/fabrikamprime project="Fabrikam Fiber"


        az repos import create --git-source-url https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-DevOps-ControlRepo --repository AN-Azure-DevOps-ControlRepo-non-SAP

        az devops configure --defaults organization=https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-DevOps-ControlRepo project="AN-Azure-TestProject-ControlRepo"

/usr/bin/bash --noprofile --norc /home/vsts/work/_temp/e0878650-06f2-4f34-abe6-1e99778674fc.sh
WARNING: Failed to store PAT using keyring; falling back to file storage.
WARNING: You can clear the stored credential by running az devops logout.
WARNING: Refer https://aka.ms/azure-devops-cli-auth to know more on sign in with PAT.

        




