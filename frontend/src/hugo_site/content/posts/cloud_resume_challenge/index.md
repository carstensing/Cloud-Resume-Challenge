+++
date = "2024-10-17T14:55:59-07:00"
draft = true
lastmod = "2025-04-02"
title = "Cloud Resume Challenge [Draft]"
summary = """A work in progress."""
+++

<!-- badges -->

[![Lambda Test](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/lambda_test.yaml/badge.svg)](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/lambda_test.yaml)

The [**Cloud Resume Challenge**][cloud_resume_challenge] is a multi-step
project designed to help aspiring cloud developers gain real-world experience
with cloud technologies by building and deploying a **personal resume
website**.

This repo showcases my journey through the challenge and what I learned along
the way.

**Check out my website at [carsten-singleton.com][my-website].**

<!-- reference links -->

[my-website]:
    https://carsten-singleton.com

[cloud_resume_challenge]:
    https://forrestbrazeal.com/2020/04/23/the-cloud-resume-challenge/

## Introduction

### Why Learn Cloud

The entry-level job market for roles in software development and IT operations
are oversaturated and highly competitive. Traditional education often lacks
cloud-specific training, resulting in a shortage of skilled engineers. As more
companies depend on cloud services for critical business operations, the
demand for jobs outweighs the supply of trained engineers.

Fortunately, cloud engineering is accessible to those without a degree, thanks
to numerous certifications and online learning resources. Engineers gain
experience in system administration, networking, security, automation, and
programming, building a diverse set of highly transferable skills.
Additionally, cloud engineering offers competitive salaries, remote work
opportunities, and significant potential for career growth.

These factors are especially attractive to me, as they support my long-term
goal of becoming a DevOps Engineer.

### What is the Cloud Resume Challenge

The [**Cloud Resume Challenge**][cloud_resume_challenge], by [Forrest
Brazeal][forrest_brazeal], is a project outline that simulates end-to-end cloud
development—culminating in a personal resume website. The challenge provides
hands-on experience with cloud technologies and serves as a portfolio piece for
job seekers in the field. Any cloud service provider can be used to complete
this challenge. I chose [Amazon Web Services][aws].

Forrest also sells a [project guide][cloud_resume_challenge_book] that details
the best ways to go about the challenge and includes additional modifications
for even more hand-on practice. I found it to be incredibly helpful.

General outline:

- **Certification**: Obtain a cloud certification (AWS Certified Cloud
  Practitioner).

- **Frontend**: Create a static website (Hugo) and host it using a cloud
  provider (S3, Route53 and CloudFront).

- **Backend**: Implement a visitor counter using a serverless function,
  database and a REST API (Lambda, DynamoDB and API Gateway).

- **Infrastructure as Code (IaC)**: Automate deployments with Terraform.

- **CI/CD**: Set up automated testing (pytest and PlayWright) and deployment
  pipelines (GitHub Actions).

<!-- reference links -->

[forrest_brazeal]:
    https://forrestbrazeal.com/

[aws]:
    https://aws.amazon.com/what-is-aws/

[cloud_resume_challenge_book]:
    https://cloudresumechallenge.dev/book/

## Steps I Took

### 1. AWS Certification

Without any prior cloud experience the project guide was difficult to
understand. As I studied for the [AWS Certified Cloud
Practitioner][certified_cloud_practitioner] exam, I learned about vital cloud
concepts and the specific services used in the project.

I spent over 60 hours watching lectures, reading, and answering over 1900
practice problems. **Make sure your study material is up to date** with the
current exam version and outline. I studied old material which set
me back some time.

After completing this project, I intend on obtaining the [AWS Certified
Solutions Architect][certified_solutions_architect] certification as well.

Free resources that I used to pass the exam (Oct 2024):

- [Andrew Brown's lecture videos][lecture]
- [Sthithapragna's practice questions][questions]

<!-- reference links -->

[certified_cloud_practitioner]:
    https://aws.amazon.com/certification/certified-cloud-practitioner/

[certified_solutions_architect]:
    https://aws.amazon.com/certification/certified-solutions-architect-professional/

[lecture]:
    https://www.youtube.com/watch?v=NhDYbskXRgc&list=LL&index=11

[questions]:
    https://www.youtube.com/playlist?list=PL7GozF-qZ4KeQftuqU3yxvQ-f3eFNUiuJ

### 2. Hugo Static Site

I wanted to create a website that I could use for more than my resume.
Something simple that worked with Markdown so I could reuse my repository
READMEs. My search lead me to a static website framework called Hugo. Hugo
builds and serves the site to a localhost, providing a real-time preview of the
site. This is super handy for developing locally before moving onto hosting
with AWS. Overall, I'm happy that I chose to use Hugo over building a basic
HTML and CSS static site that I would dread updating.

Free Resources to learn Hugo:

- [Hugo documentation][hugo]
- [Giraffe Academy][giraffe_academy]

### 3. AWS Organizations

AWS Organizations is a centralized account management service that helps
businesses manage multiple AWS accounts efficiently. It provides security,
governance, cost optimization, and automation at scale.

- [What is AWS Organizations?][what_is_aws_organizations]
- [Terminology and concepts for AWS Organizations][terminology_and_concepts_for_aws_organizations]

[what_is_aws_organizations]:
    https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html
[terminology_and_concepts_for_aws_organizations]:
    https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html

Okay great, but why did I use it for a single-person project? Besides to get
some hands-on experience, here is what I found:

#### Account Protection

Using the AWS root account for development is a bad practice due to its
unlimited privileges, making it prone to accidental misconfigurations or
deletions that cannot be restricted by IAM policies. It also poses a
significant security risk since a compromised root account grants full control
over all AWS resources. This can cost **thousands** of dollars! So to protect
yourself from yourself and attackers, develop in a member account, not root.

#### IAM Roles and Policies

Member accounts have their permissions set by root. I gave my dev account
PowerUserAccess, which grants full access to AWS services and resources, but
does not allow management of Users and groups. Sounds like that should be all I
need to code some stuff right? Nope! Thanks to IAM roles and policies.

**Roles** are like logos that are assigned to users, groups, or services,
representing their identity and the level of access they have. **Policies** are
the specific **permissions** that are attached to a role (or directly to a user
or group), defining what actions they can perform.

Imagine a facility with different levels of security. They hire a cleaning
company, and anyone with the company logo (role) on their uniform or vehicle is
allowed on-site. However, the cleaning crew doesn't have access to the fourth
floor of the building. The role is the cleaning company's logo, and the policy
is the restriction that they cannot go to the fourth floor.

The company's vehicle (which could be used for drop-offs) also has the logo and
can enter the premises. However, not just anyone can drive the vehicle; only
authorized drivers (users with the correct role) can use it. The driver assumes
the role associated with the vehicle and is granted access based on the
permissions attached to that role. This is an example of a service role that
can be assumed by users to gain temporary access to resources they otherwise
wouldn't have.

As I moved from one service to another, I found which permissions were lacking.
Following the principle of least privilege, I added only the permissions
required for each specific task. This incremental approach helped me learn how
services use IAM roles and policies, and how they impact development on AWS.

#### Free Tier

The hack to creating member accounts is to use email sub-addressing instead of
creating a new email. For example, if the root email is <myemail@mail.com>, the
dev account can be created with <myemail+dev@mail.com>. Even if the root account
is no longer eligible for the Free Tier, the member accounts are eligible
because they are newly created. After a year, when the dev account loses Free
Tier eligibility, simply create another dev account with a different
sub-address. Infinite Free Tier!

Be aware that even with multiple Free Tier accounts within an organization, the
benefits don't increase. As long as one or more accounts are Free Tier
eligible, the entire organization will _share_ the standard Free Tier benefits.

- [AWS Free Tier FAQs][aws_free_tier_faqs]

[aws_free_tier_faqs]:
    https://aws.amazon.com/free/free-tier-faqs/

#### SSO Login

To use the AWS Command Line Interface (CLI) locally, account credentials
(access keys) must be stored on your computer. However, this poses a
significant security risk, since they can accidentally be published to
platforms like GitHub. The IAM Identity Center for AWS Organizations provides
single sign-on (SSO) access with credentials that expire. These temporary
credentials reduce the risk of leaked keys compromising an account. Plus, sso
login is very convenient to use, even from the CLI.

- [SSO setup guide for personal development][sso_for_personal_development]

To avoid frequent logins, set the session duration to more than an hour.

<!-- reference links -->

[sso_for_personal_development]:
    https://dev.to/aws-builders/minimal-aws-sso-setup-for-personal-aws-development-220k

### 4. S3, Route53 and Cloudfront

I purchased a domain name through Route 53 and created an S3 bucket to store my
site files built by Hugo. After that, I used CloudFront to enable HTTPS and
content delivery. AWS has guides on how to do all of this, which made it
very easy.

Learning Resources:

- [Configuring a static site using a custom domain registered with Route 53][s3_static_site_custom_domain]
- [CloudFront and HTTPS][s3_static_site_cloudfront_and_https]

<!-- reference links -->

[s3_static_site_custom_domain]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html

[s3_static_site_cloudfront_and_https]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-cloudfront-walkthrough.html

Some things weren't so obvious and required some investigation / trial and
error. Here is what I learned:

#### Route 53 Name Server Issue

For DNS to work properly, the record for routing traffic to your domain name
must use the same name servers that the hosted zone uses. I recreated the
hosted zone and record multiple times while following the guide and was
auto-generated differing values, which made DNS not work.

#### CloudFront Cache Update

CloudFront caches S3 files for the static site, and any updates must be
reflected in the cache. The expiration time for cached files be configured,
with different lengths of time offering different pros and cons. Read their
[cache expiration guide][cloudfront_cache_expiration] for more details.

So, even after updating S3, your domain won't serve the updated files until they
are cycled out. To avoid waiting for files to expire, they can be manually
invalidated or automatically updated if versioned file names are used.

<!-- reference links -->

[cloudfront_cache_expiration]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html

##### Invalidations

Transferring new files to the cache incurs costs for both methods, and
invalidations have an additional [cost after 1,000 submissions][invalidation_cost]. So, it's worth it to be smart about invalidation. Each deleted or modified file must be explicitly listed in the invalidation with its full bucket path.
Getting these file paths takes some work but isn't too hard.

<!-- reference links -->

[invalidation_cost]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PayingForInvalidation.html

##### Versioned File Names

[AWS recommends versioned file names][invalidate_vs_versioned_files], but the
implementation requires more work since the files names have to be managed.
[This is a great post][cloudfront_hashed_file_names] about how to
use hashed file names to update the cache.

<!-- reference links -->

[invalidate_vs_versioned_files]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html#Invalidation_Expiration

[cloudfront_hashed_file_names]:
    https://stackoverflow.com/questions/72468436/how-best-to-serve-versioned-s3-files-from-cloudfront

### 5. AWS CLI

The AWS CLI tool is awesome because it does things that the online console
can't. Certain tasks can be automated with scripts and other are just more
efficient. It's also a fantastic learning tool for backwards engineering
because the console often does more than one action at a time. I learned this
after I redid part 4 only using the CLI.

- [CLI install guide][cli_install_guide]
- [CLI command completion][cli_command_completion]
- [CLI command reference][cli_doc]

[cli_install_guide]:
    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

[cli_command_completion]:
    https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html

[cli_doc]:
    https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html

#### SSO for CLI

Some configuration is required to use SSO with the AWS CLI. I prefer editing the
`~/.aws/config` file directly instead of using their setup wizard. Follow the user guide:

- [SSO config for CLI][sso_config_for_cli]

To login:

```bash
aws sso login --profile my-profile
```

Automatically loading a profile requires exporting it to your shell startup
script:

```bash
echo "export AWS_PROFILE=my-profile" >> ~/.bashrc
source ~/.bashrc
```

For safety, it's better to leave `AWS_PROFILE` unset when using multiple
profiles, to ensure actions are performed with the correct profile.

<!-- reference links -->

[sso_config_for_cli]:
    https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#cli-configure-sso-manual

### 6. DynamoDB, Lambda, API Gateway and JavaScript

I learned a **ton** on this chuck of the project. I understood the concept of
how a website, a database and an API interacted, but actually building it all
really challenged me. Again, since I didn't have any experience with these
services, I started with the AWS console.

I broke everything down into the smallest steps I could and then pieced them
together to slowly. I took these steps:

1. Read and write to DynamoDB from Lambda TODO

<https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/programming-with-python.html>

### 7. pytests

When migrating to local development, I wanted to replicate the integrated test
function available in the Lambda online console. Using pytest enabled me to
practice test-driven development, automate testing, and accelerate the
development process.

I configured my Python virtual environment to run pytest-watch on startup,
which automatically runs tests when the source files are saved. Using
pytest-xdist makes it possible to run tests in parallel, speeding up test
times. Configuration of pytest.ini is needed to use pytest-xdist automatically
when pytest-watch runs the tests.

To autorun tests:
    Add to the venv/bin/activate file:
      gnome-terminal -- bash -c "ptw --ext=.py,.json"
    If your terminal is different, change "gnome-terminal"

```ini
# pytest.ini

[pytest]
addopts = -n auto --disable-warnings
```

### 8. Terraform

Use the existing AWS infrastructure as a reference when writing Terraform for
this project. Create identical resources with Terraform and then replace the
original. Leverage AWS CLI commands to gather the required details for
Terraform definitions. For example, the [get-method CLI
command][cli_get_method] returns the data needed for defining the [API Gateway
method in Terraform][api_gateway_method].

- [Terraform AWS documentation][terraform_aws_doc]

If you have zero Terraform experience like I did, Rahul Wagh has a fantastic
video on [how to create a Lambda function is
Terraform][deploy_lambda_with_terraform], which cleared up a lot of confusion.

For Lambda, utilize the `source_code_hash` argument to trigger a rebuild
whenever the Python code changes and remember to create an
`aws_lambda_permission` resource for API Gateway when you get there.

For API Gateway, remember to take care of the SDK generation. I use the
`terraform_data` resource to run a bash shell script to update the JavaScript
files.

[api_gateway_method]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

[cli_get_method]:
    https://awscli.amazonaws.com/v2/documentation/api/latest/reference/apigateway/get-method.html

[terraform_aws_doc]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs

[deploy_lambda_with_terraform]:
    https://www.youtube.com/watch?v=JSR7U700h0U

### 9. Source Control

Git and GitHub plus GitHub Projects. SOMUCHTODO

### 10. CI/CD

GitHub Actions. SOMUCHTODO

## Technology Used

- [AWS CLI][aws_cli]
- [Hugo][hugo]
- [pytest][pytest]
- [PlayWright for Python][playwright_for_python]
- [Terraform][terraform]

- Git
- Github
- VSCode
- Ubuntu
- Firefox Developer Tools

<!-- reference links -->

[aws_cli]:
    https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html

[hugo]:
    https://gohugo.io/documentation/

[giraffe_academy]:
    https://youtube.com/playlist?list=PLLAZ4kZ9dFpOnyRlyS-liKL5ReHDcj4G3&feature=shared

[pytest]:
    https://docs.pytest.org/en/stable/

[playwright_for_python]:
    https://playwright.dev/python/docs/api/class-playwright

[python_virtual_environments]:
    https://realpython.com/python-virtual-environments-a-primer/

[terraform]:
    https://developer.hashicorp.com/terraform?product_intent=terraform
