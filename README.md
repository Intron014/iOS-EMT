Little guide for the Submodules

```
git checkout -b EMT-Folder
git filter-repo —path “EMT Times/EMT”
git checkout main
git remote add origin ssh://git@31.220.77.64:8922/Intron014/iOS-EMT.git
git pull origin main —rebase
git push origin EMT-Folder
```