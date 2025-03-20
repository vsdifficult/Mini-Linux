# Option 1: Use Docker Hub (will prompt for login)
chmod +x run.sh
./run.sh --registry dockerhubusername

# Option 2: Skip Docker Hub push (use local images only)
./run.sh --local-registry --skip-terraform

bash run.sh --local-registry --skip-terraform