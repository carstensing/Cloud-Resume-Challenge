# Manual Site Update

All of these steps will be automated later in the project.

1. Delete and rebuild `src/hugo_site/public/` to refresh Hugo.

    `rm -fr src/hugo_site/public`

    `cd src/hugo_site`

    `hugo`

2. Sign in to AWS SSO.

3. Download the bucket.

    `aws s3 sync s3://carsten-singleton.com old_bucket_files`

4. Add new / updated files from `public/` to the bucket.

    `aws s3 sync src/hugo_site/public s3://carsten-singleton.com`

5. Get the list of files that were deleted in this update.

    `rsync -rvni --ignore-existing old_bucket_files/ src/hugo_site/public/ > files-to-delete.txt`

6. Get rid of the prepended text you don't need in VSCode.

7. Delete files from the bucket that aren't in `public/`.

    `cat files-to-delete.txt | xargs -I {} aws s3 rm "s3://carsten-singleton.com/{}"`

8. Get files to invalidate in CloudFront.

    `rsync -rcni old_bucket_files/ src/hugo_site/public/ > files-to-invalidate.txt`

9. Get rid of the prepended text you don't need in VSCode.

10. Invalidate the files in the AWS console.
