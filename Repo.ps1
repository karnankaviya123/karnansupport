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





	
            Azure DevOps Services | Sign In
        




