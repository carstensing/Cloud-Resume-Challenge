#! /usr/bin/bash

cloudfront_dist="${1}"
site_bucket="s3://carsten-singleton.com"
public_path="../hugo_site/public"
escaped_public_path=$(echo "${public_path}" | sed 's|/|\\/|g')  # Escape `/` for Perl.
bucket_download_dir="bucket_files"
output_files=("diff_bucket_and_public.txt" 
              "only_in_public.txt" 
              "only_in_bucket.txt" 
              "updated_files.txt" 
              "invalidations.txt" 
              "batch_invalidations.json")

rm -fr ../hugo_site/public
hugo -D -s ../hugo_site
echo "public/ updated."

#             source         destination
aws s3 sync "${site_bucket}" "${bucket_download_dir}"
echo "Bucket downloaded."

diff -rq "${bucket_download_dir}" "${public_path}" > "${output_files[0]}"

# For `diff -rq dir1 dir2`, all subdirectories their files that are only in one
# dir get printed as: Only in dir: subdir. This hides all of the subfiles which
# are needed to update the S3 bucket. This loop gets the subfile paths.
dirs=("${escaped_public_path}" "${bucket_download_dir}")
for i in {0..1}
do
    perl -nle "print \$2 if /(Only in \Q${dirs[i]}\E: )(.*\..*)/" "${output_files[0]}" > "${output_files[i+1]}"

    perl -nle "print \"\$1\/\$2\" if /Only in (\Q${dirs[i]}\E.*): (?!.*\.\w+$)(.+$)/" "${output_files[0]}" | while read dir; do
    find "${dir}" -type f
    done | perl -nle "print \$2 if /(\Q${dirs[i]}\E\/)(.*\..*)/" >> "${output_files[i+1]}"
done

perl -nle "print \$2 if /(Files \Q${bucket_download_dir}\E\/)([^ ]+)/" "${output_files[0]}" > "${output_files[3]}"

echo "Diff files generated."

# Run aws s3 sync for each file.
while IFS= read -r file; do
  aws s3 sync "${public_path}" "${site_bucket}" --delete --exclude "*" --include "${file}"
done < <(cat "${output_files[1]}" "${output_files[2]}" "${output_files[3]}")

echo "Files synced."

cat "${output_files[1]}" "${output_files[3]}" | sed 's|^|/|' > "${output_files[4]}"

jq -n --argjson quantity "$(wc -l < ${output_files[4]})" \
      --argjson items "$(jq -R . < ${output_files[4]} | jq -cs .)" \
      --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
      '{Paths: {Quantity: $quantity, Items: $items}, CallerReference: $timestamp}' \
      > "${output_files[5]}"

echo "Invalidations created."

if [ -s "${output_files[4]}" ]; then
    # File is not empty.
    aws cloudfront create-invalidation \
    --distribution-id "${cloudfront_dist}" \
    --invalidation-batch "file://${output_files[5]}"

    echo "Files invalidated."
fi

rm -fr ${bucket_download_dir}

for file in "${output_files[@]}"
do
    rm -fr "${file}"
done

echo "Temp files deleted."
