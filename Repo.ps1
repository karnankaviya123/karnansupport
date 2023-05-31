- script: |
        MY_PAT=ps4rm6zonfja3xrguayipeis3n62njfzvlcuziu76b5xljax34ca
        B64_PAT=$(printf "%s"":$MY_PAT" | base64)
        git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-DevOps-ControlRepo/_git/AN-Azure-DevOps-ControlRepo-non-SAP -b main
        cd AN-Azure-DevOps-ControlRepo-non-SAP
        ls -latr
        echo "Something"
        cd ../
        git -c http.extraHeader="Authorization: Basic ${B64_PAT}" clone https://an-de-ohg-sbi@dev.azure.com/an-de-ohg-sbi/AN-Azure-TestProject-ControlRepo/_git/AN-Azure-TestProject-ControlRepo
        cd AN-Azure-TestProject-ControlRepo
        ls -latr
        cd ../AN-Azure-DevOps-ControlRepo-non-SAP
        cp -p .docs README.md ../AN-Azure-TestProject-ControlRepo
        git add .
        git commit -m "added base files"
        cd ../AN-Azure-TestProject-ControlRepo
        ls -ltra
