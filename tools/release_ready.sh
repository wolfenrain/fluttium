# Ensures that the package is ready for a release.
# 
# Will update the version.dart file and update the CHANGELOG.md.
#
# Run in current directory with existing version
# `./release_ready.sh`
#
# Try and run with new version
# `./release_ready.sh <version>

# Check if current directory has a pubspec.yaml, if so we assume it is correctly set up.
if [ ! -f "pubspec.yaml" ]; then
    echo "$(pwd) is not a valid package, missing pubspec.yaml."
    exit 1
fi

currentBranch=$(git symbolic-ref --short -q HEAD)
if [[ ! $currentBranch == "main" ]]; then
    echo "Releasing is only supported on the main branch."
    exit 1
fi

# Get package information
package_version=$(dart pub deps --json | pcregrep -o1 -i '"version": "(.*?)"' | head -1)
package_name=$(dart pub deps --json | pcregrep -o1 -i '"name": "(.*?)"' | head -1)

# Get new version
new_version="";
if [ "$1" != "" ]; then
  new_version="$1";
else
  new_version="$(dart pub deps --json | pcregrep -o1 -i '"version": "(.*?)"' | head -1)";
fi

if [ "$new_version" != "$package_version" ]; then
    echo "Updating version to $new_version"
    sed -i '' "s/version: $package_version/version: $new_version/g" pubspec.yaml
fi

# Update dart file with new version.
dart run build_runner build --delete-conflicting-outputs > /dev/null

if grep -q $new_version "CHANGELOG.md"; then
    echo "CHANGELOG already contains version $new_version."
    exit 1
fi

# Add a new version entry.
echo "# ${new_version}\n\nTODO: entries\n\n$(cat CHANGELOG.md)" > CHANGELOG.md

echo "CHANGELOG for $package_name generated, add entries here: $(pwd)/CHANGELOG.md"

echo "Creating git branch for $package_name@$new_version"
git checkout -b "chore($package_name)/$new_version" > /dev/null

