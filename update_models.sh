#!/usr/bin/env bash

# Do NOT set -v or -x or your GitHub API token will be leaked!
set -ue # exit with nonzero exit code if anything fails

# Function that updates a given model:
update_model()
{
	local model_name=$(echo $folder_name | cut -c 3-) #remove the "ec" start

	# Move model to proper folder:
	mv ./model.mat ./$folder_name
	cd ./$folder_name

	# Create copy of GECKO w/replaced scripts/data (if any) & removed models:
	cp ../GECKO ./GECKO
	for file_name in $(ls ./scripts); do
		gecko_path = $(ls ./GECKO/**/$file_name)
		cp ./scripts/$file_name gecko_path
	done
	for file_name in $(ls ./data); do
		gecko_path = $(ls ./GECKO/**/$file_name)
		cp ./data/$file_name gecko_path
	done
	rm -rf ./GECKO/models/ec*

	# Matlab script:
	matlab -nosplash -nodesktop -r "updateModel($model_name)"

	# Move model files:
	rmdir -rf ./model
	mv ./GECKO/models/ec* ./model

	# Save associated versions & update SHA-1:
	model_version=$(cat ./model_version.txt)
	echo -e "${model_name}\t${model_version}\n${versions}" > ./dependencies.txt
	echo $new_sha1 > ./latest_sha1.txt

	# Remove the downloaded model + the copied GECKO:
	rm ./model.mat
	rm ./model_version.txt
	rm -rf ./GECKO
	cd ..
}

# Function that clones a repo and stores the name/version pair in "versions" (global var):
clone_repo()
{
	local link=$1
	local repo_name=$2
	git clone --depth=1 $link
	cd ./$repo_name
	local version=$(git describe --tags)
	versions="${versions}${repo_name}\t${version}\n"
	cd ..
}

# Main script:

versions=""
clone_repo https://github.com/SysBioChalmers/GECKO.git GECKO
clone_repo https://github.com/SysBioChalmers/RAVEN.git RAVEN
clone_repo https://github.com/opencobra/cobratoolbox.git cobratoolbox

cd ./GECKO
new_gecko=$(git describe --tags)
cd ..

# Go through each folder in root that starts with "ec":
for folder_name in $(ls -d ec*); do

	# Download .mat file from URL and get checksum:
	file_url=$(cat ./${folder_name}/file_url.txt)
	wget -O ./model.mat $file_url
	new_sha1=$(sha1sum model.mat | awk '{print $1;}')

	# Parse previous sha1 and GECKO version:
	latest_sha1=$(cat ./${folder_name}/latest_sha1.txt)
	latest_gecko=$(awk  -F"\t" '$1 == "GECKO" {print $2;}' ./${folder_name}/dependencies.txt)

	# If either sha1 or gecko have changed, update the model:
	if [[ "${new_sha1}" != "${latest_sha1}" || "${new_gecko}" != "${latest_gecko}" ]]; then
		echo "Updating ${folder_name}..."
		update_model
	else
		echo "${folder_name} is up to date."
		rm ./model.mat
	fi
done

rm -rf ./GECKO
rm -rf ./RAVEN
rm -rf ./cobratoolbox
