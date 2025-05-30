# Cloud Resume Challenge <!-- omit from toc -->

<!-- badges -->

[![Run Terraform](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/run_terraform.yaml/badge.svg)](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/run_terraform.yaml)
[![Lambda Test](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/lambda_test.yaml/badge.svg)](https://github.com/carstensing/Cloud-Resume-Challenge/actions/workflows/lambda_test.yaml)

The [Cloud Resume Challenge] is a multi-step project designed to help
aspiring cloud developers gain real-world experience with cloud technologies by
building and deploying a **personal resume website**.

This repo showcases my journey through the challenge and what I learned along
the way.

**Check out my website at [carsten-singleton.com].**

[carsten-singleton.com]: https://carsten-singleton.com

[Cloud Resume Challenge]:
    https://forrestbrazeal.com/2020/04/23/the-cloud-resume-challenge/

## Contents <!-- omit from toc -->

- [Introduction](#introduction)
    - [Why Learn Cloud](#why-learn-cloud)
    - [What is the Cloud Resume Challenge](#what-is-the-cloud-resume-challenge)
        - [Outline](#outline)
        - [Site Diagram](#site-diagram)
- [Steps I Took](#steps-i-took)
    - [1. AWS Certification](#1-aws-certification)
    - [2. Hugo Static Site](#2-hugo-static-site)
    - [3. AWS Organizations](#3-aws-organizations)
        - [Account Protection](#account-protection)
        - [IAM Roles and Policies](#iam-roles-and-policies)
        - [Free Tier](#free-tier)
        - [SSO Login](#sso-login)
    - [4. S3, Route 53 and Cloudfront](#4-s3-route-53-and-cloudfront)
        - [Name Servers](#name-servers)
        - [`s3 sync --delete` Bug](#s3-sync---delete-bug)
        - [CloudFront Cache Update](#cloudfront-cache-update)
            - [File Expiration](#file-expiration)
            - [Versioned File Names](#versioned-file-names)
            - [Invalidations](#invalidations)
    - [5. AWS CLI](#5-aws-cli)
        - [SSO for CLI](#sso-for-cli)
    - [6. DynamoDB, Lambda, API Gateway and JavaScript](#6-dynamodb-lambda-api-gateway-and-javascript)
        - [Lambda](#lambda)
        - [API Gateway](#api-gateway)
        - [DynamoDB](#dynamodb)
        - [JavaScript](#javascript)
    - [7. pytests](#7-pytests)
        - [Fixtures and Parameterization](#fixtures-and-parameterization)
        - [Python Virtual Environment](#python-virtual-environment)
    - [8. Terraform](#8-terraform)
        - [Reliable Change Detection for External Files](#reliable-change-detection-for-external-files)
        - [Remote State](#remote-state)
        - [Resource Tips](#resource-tips)
    - [9. Source Control](#9-source-control)
    - [10. CI/CD With GitHub Actions](#10-cicd-with-github-actions)
- [Conclusion](#conclusion)

## Introduction

### Why Learn Cloud

The entry-level job market for roles in software development and IT operations
are oversaturated and highly competitive. Traditional education often lacks
cloud-specific training, resulting in a shortage of skilled engineers. As more
companies depend on cloud services for critical business operations, the demand
for jobs outweighs the supply of trained engineers.

Fortunately, cloud engineering is accessible to those without a degree, thanks
to numerous certifications and online learning resources. Engineers gain
experience in system administration, networking, security, automation, and
programming, building a diverse set of highly transferable skills.
Additionally, cloud engineering offers competitive salaries, remote work
opportunities, and significant potential for career growth.

These factors are especially attractive to me, as they support my long-term
goal of becoming a DevOps Engineer.

### What is the Cloud Resume Challenge

The [Cloud Resume Challenge], by [Forrest Brazeal], is a project outline
that simulates end-to-end cloud development—culminating in a personal resume
website. The challenge provides hands-on experience with cloud technologies and
serves as a portfolio piece for job seekers in the field. Any cloud service
provider can be used to complete this challenge. I chose [Amazon Web
Services].

[Forrest Brazeal]: https://forrestbrazeal.com/

[Amazon Web Services]: https://aws.amazon.com/what-is-aws/

Forrest also sells a [project guide] that details the best ways to go about
the challenge and includes additional modifications for even more hand-on
practice. I found it to be incredibly helpful.

[project guide]: https://cloudresumechallenge.dev/book/

#### Outline

- **Certification**: Obtain a cloud certification (AWS Certified Cloud
  Practitioner).
- **Frontend**: Create a static website (Hugo) and host it using a cloud
  provider (S3, Route 53 and CloudFront).
- **Backend**: Implement a visitor counter using a serverless function,
  database and a REST API (Lambda, DynamoDB and API Gateway).
- **Infrastructure as Code**: Automate deployments with Terraform.
- **CI/CD**: Setup automated testing (pytest) and deployment
  pipelines (GitHub Actions).

#### Site Diagram

![Site Diagram]

[Site Diagram]: ./images/site_diagram.svg

## Steps I Took

### 1. AWS Certification

The project guide recommends taking the exam prior to starting the project to
set a knowledge baseline. I read through the later sections and found all of
the AWS jargon to be intimidating and impossible to understand. So, I studied
for the [AWS Certified Cloud Practitioner] exam.

[AWS Certified Cloud Practitioner]:
    https://aws.amazon.com/certification/certified-cloud-practitioner/

I spent over 60 hours watching lectures, reading, and answering over 1900
practice problems. Make sure your study material is up to date with the
current exam version and outline. I mistakenly studied some old material, which
set me back some time. Andrew Brown has an excellent, [free lecture series for
the CCP exam] that I used to pass the exam.

[free lecture series for the CCP exam]:
    https://www.youtube.com/watch?v=NhDYbskXRgc&list=LL&index=11

In hindsight, I’d recommend taking the exam _after_ completing the project, since the hands-on learning is far more effective and cohesive. While the project might be harder to grasp at first, the trial-and-error process is what truly helps the information stick. Without any real experience connecting services, studying for the exam ends up being mostly memorization—which isn’t nearly as valuable or practical.

After completing this project, I intend to obtain the [AWS Certified
Solutions Architect] certification.

[AWS Certified Solutions Architect]:
    https://aws.amazon.com/certification/certified-solutions-architect-professional/

### 2. Hugo Static Site

I wanted to create a website that could be used for more than just my
resume—something simple and well-suited for developers. Hugo is an open-source
static site generator that uses Markdown files as content sources, making it
easy to integrate with content on GitHub. It’s easy to learn, and with a wide
selection of themes available, you can get a polished website up and running
quickly. Hugo can build and serve your site to a localhost, providing a
real-time preview while developing locally. Overall, I'm happy that I chose to
use Hugo over building a basic HTML and CSS static site that I would dread
updating and maintaining.

Free Resources to learn Hugo:

- [Hugo documentation]
- [Giraffe Academy]

[Hugo documentation]: https://gohugo.io/documentation/

[Giraffe Academy]:
    https://youtube.com/playlist?list=PLLAZ4kZ9dFpOnyRlyS-liKL5ReHDcj4G3&feature=shared

### 3. AWS Organizations

AWS Organizations is a centralized account management service that helps
businesses manage multiple AWS accounts efficiently. It provides security,
governance, cost optimization, and automation at scale.

- [What is an AWS Organization?]
- [Terminology and concepts for AWS Organizations]

[What is an AWS Organization?]:
    https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html

[Terminology and concepts for AWS Organizations]:
    https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html

Other than gaining hands-on experience, why use AWS for a single-person
project?

#### Account Protection

Using the AWS root account for development is a bad practice due to its
unlimited privileges, making it prone to accidental misconfigurations or
deletions that cannot be restricted by IAM policies. It also poses a
significant security risk since a compromised root account grants full control
over all AWS resources. This can cost **thousands** of dollars! So protect you
wallet from yourself and attackers by developing in a member account.

#### IAM Roles and Policies

Member accounts have their permissions set by root. I gave my dev account
[PowerUserAccess], which grants full access to most AWS services and
resources except IAM. Sounds like that should be all I need to code some stuff
right? Nope! Because services often interact with each other and need IAM
permissions to do so. For example, by default, Lambda will create an execution
role with permissions to upload logs to Amazon CloudWatch Logs. So I couldn't
even create a Lambda function without IAM permissions.

[PowerUserAccess]:
    https://docs.aws.amazon.com/aws-managed-policy/latest/reference/PowerUserAccess.html

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
because they are newly created. After a year, when the account loses Free
Tier eligibility, create another account in the org to get infinite Free Tier!

Be aware that even with multiple Free Tier accounts within an organization, the
benefits don't increase. As long as one or more accounts are Free Tier
eligible, the entire organization will _share_ the standard Free Tier benefits.

- [AWS Free Tier FAQs]

[AWS Free Tier FAQs]: https://aws.amazon.com/free/free-tier-faqs/

#### SSO Login

To use the AWS Command Line Interface (CLI) locally, account credentials
(access keys) must be stored on your computer. However, this poses a
significant security risk, since they can accidentally be published to
platforms like GitHub. The IAM Identity Center for AWS Organizations provides
single sign-on (SSO) access with credentials that expire. These temporary
credentials reduce the risk of leaked keys compromising an account. Plus, sso
login is very convenient to use, even from the CLI.

- [SSO setup guide for personal development] (AWS SSO is now AWS IAM Identity
  Center)

[SSO setup guide for personal development]:
    https://dev.to/aws-builders/minimal-aws-sso-setup-for-personal-aws-development-220k

> [!TIP]
> To avoid frequent logins, set the session duration to more than an hour.

### 4. S3, Route 53 and Cloudfront

I purchased a domain name through **Route 53** and created an **S3** bucket to
store my site files built by Hugo. After that, I used **CloudFront** to enable
HTTPS and content delivery. AWS has guides on how to do all of this, but it can
still be tricky. Follow them in this order:

- [Configuring a static site using a custom domain registered with Route 53]
- [Requesting a public certificate with ACM for HTTPS] (step 2 only)
- [Configuring CloudFront]

[Configuring a static site using a custom domain registered with Route 53]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html

[Requesting a public certificate with ACM for HTTPS]:
    https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started-cloudfront-overview.html#getting-started-cloudfront-request-certificate

[Configuring CloudFront]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-cloudfront-walkthrough.html

Some things weren't so obvious and required some investigation with some trial
and error. Here is what I learned:

#### Name Servers

For DNS to work properly, the name servers connected to the registered domain
in Route 53 must match the same name servers in the hosted zone. The hosted
zone's name servers cannot be set manually, so you'll have to update the
registered domain.

#### `s3 sync --delete` Bug

The easiest way to update S3 is by using the aws s3 sync my_website s3_bucket
--delete command, which recursively copies new and updated files from the
source directory to the destination. The --delete option removes files from the
destination that no longer exist in the source.

This would have made my life much easier—except I noticed that files weren’t
actually being deleted correctly. In hindsight, this may have been a mistake on
my part, but at the time I was convinced I needed to circumvent syncing
directories.

My solution was to manually identify all new, updated, and deleted files, and
then sync each file individually. Running the command this way solved the issue
with deletions not working properly. I had to learn a lot about bash scripts in
order to parse and format the files paths, so this portion took me a while to
get right. Fortunately, that experience made future scripting tasks much
easier.

#### CloudFront Cache Update

CloudFront caches S3 files for the static site so any S3 updates must be
reflected in the cache. Your domain won't serve the updated files until they
are cycled out, which can happen three ways: files expire within a set time,
versioned files have been updated with a new version, or files are manually
invalidated.

##### File Expiration

The expiration time for cached files can be configured, with different lengths
of time offering different pros and cons. Read the [cache expiration guide]
for more details. However, when I updated my site I want to see changes
immediately, making this not the solution.

[cache expiration guide]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html

##### Versioned File Names

AWS will automatically update files or directories with a changed version
identifier. This requires renaming each file to be updated and updating all
corresponding references within other files. Using hashes instead of
incremental version numbers might simplify the process. However, changing file
references within files screams terrible bugs to me so I decided not to use
versioning. Additionally, any deleted files still require invalidation.

Here is some more details on versioning:

- [Invalidation vs versioning]
- [Use versioning to update content]
- [Example on how to effectively use versioning]

[Invalidation vs Versioning]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html#Invalidation_Expiration

[Use versioning to update content]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/UpdatingExistingObjects.html#ReplacingObjects

[Example on how to effectively use versioning]:
    https://stackoverflow.com/questions/72468436/how-best-to-serve-versioned-s3-files-from-cloudfront

##### Invalidations

Manual cache clearing is done through file invalidations. While data transfer
from an AWS origin such as S3 to CloudFront is free, invalidations incur
additional [cost after 1,000 submissions]. Although exceeding 1,000
invalidation requests per month is unlikely, especially after completing the
project.

[cost after 1,000 submissions]:
    https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PayingForInvalidation.html

Each deleted or modified file must be explicitly listed in the invalidation
request with its full bucket path. The entire cache can be invalidated easily,
or specific file paths can be copied and pasted for targeted invalidation,
making small updates and testing straightforward.

### 5. AWS CLI

The AWS CLI tool is awesome because it does things that the online console
can't. Certain tasks can be automated with scripts and other are just more
efficient. It's also a fantastic learning tool for backwards engineering
because the console often does more than one action at a time. I learned this
after I redid part 4 only using the CLI.

- [CLI install guide]
- [CLI auto complete]
- [CLI command reference]

[CLI install guide]:
    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

[CLI auto complete]:
    https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html

[CLI command reference]:
    https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html

#### SSO for CLI

Some configuration is required to use SSO with the AWS CLI. I prefer editing
the `~/.aws/config` file directly instead of using their setup wizard. Follow
the user guide:

- [SSOconfig for CLI][SSO_config_for_CLI]

[SSO_config_for_CLI]:
    https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#cli-configure-sso-manual

To login:

```bash
aws sso login --profile my-profile
```

Setting the default profile automatically requires exporting it to your shell
startup script:

```bash
echo "export AWS_PROFILE=my-profile" >> ~/.bashrc
source ~/.bashrc
```

For safety, it's better to leave `AWS_PROFILE` unset when using _multiple_
profiles, to ensure actions are performed with the correct profile.

> [!IMPORTANT]
> Without a default set, each command has to end with `--profile my-profile`.

### 6. DynamoDB, Lambda, API Gateway and JavaScript

The goal of this portion of the project is to implement a visitor counter that
displays how many people have accessed the website. I had a general
understanding of how a website, database, and API interact, but actually
building and piecing everything together was a  challenge—and I learned a ton
in the process.

- **Lambda** contains the logic that processes requests and updates the visitor
  count.
- **DynamoDB** stores the current count as well as hashed visitor info to prevent
  duplicate counts of the same person.
- **API Gateway** exposes the Lambda function to the internet, allowing the backend
  to make HTTP requests.
- **JavaScript** in the website sends a request to API Gateway when the home page
  loads, triggering Lambda and retrieving the updated visitor count.

To go full circle: API Gateway generates the JavaScript used by the website to
perform REST API requests. When a request is made, API Gateway forwards the
relevant information to Lambda for processing. Lambda handles the logic and
interacts with services like DynamoDB, then returns a response to API Gateway,
which delivers the final result back to the website.

#### Lambda

Lambda receives an event object whose format depends on the service that's
invoking it. Testing a Lambda is as simple as passing in a mock event object.
Lambda can also interact with other services through libraries.

- [How to use the Lambda console]
- [Learn about the Lambda handler]
- [Lambda context object]

[How to use the Lambda console]:
    https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html

[Learn about the Lambda handler]:
    https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html

[Lambda context object]:
    https://docs.aws.amazon.com/lambda/latest/dg/python-context.html

#### API Gateway

Prior to this project, I had no experience working with APIs, so the tutorials
listed below were incredibly helpful for introducing the core concepts. Through
hands-on practice, I became familiar with different HTTP methods and response
types, as well as how to work with path parameters, query strings, headers, and
CORS.

One aspect that took a bit longer to fully understand was how the event JSON
sent to Lambda is configured through the mapping template during the
integration request stage. This is important for getting information related to
counting visitors into Lambda.

Additionally, an API deployed through API Gateway isn’t accessible from the
internet until it’s been staged. Requests must be sent to the stage-specific
URL, which includes the base invoke URL, the stage name, the resource path, and
any relevant path parameters or query strings.

- [Create an API with Lambda]
- [Create a more complicated API with Lambda]
- [Mapping template transformations for REST APIs in API Gateway]
- [Variables for data transformations for API Gateway]

[Create an API with Lambda]:
    https://docs.aws.amazon.com/apigateway/latest/developerguide/getting-started-lambda-non-proxy-integration.html#getting-started-new-api

[Create a more complicated API with Lambda]:
    https://docs.aws.amazon.com/apigateway/latest/developerguide/integrating-api-with-aws-services-lambda.html

[Mapping template transformations for REST APIs in API Gateway]:
    https://docs.aws.amazon.com/apigateway/latest/developerguide/models-mappings.html

[Variables for data transformations for API Gateway]:
    https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html

> [!NOTE]
> The Lambda context object and API Gateway context variable are not
> the same.

#### DynamoDB

I ended up creating two separate tables: one to store hashed user IP addresses
along with browser information, and another to track the visitor count.
Although having an entire table dedicated to a single counter felt like
overkill, I wasn’t able to come up with a schema that made sense for combining
everything into one.

DynamoDB can be accessed from Python using the boto3 library. There are two
main interfaces: [`DynamoDB.Client`], which represents the entire DynamoDB
service and [`DynamoDB.Table`], which represents a specific table. They share
a lot of the same functionality, but I found Table's parameter formatting to be
cleaner and easier to write than Client's.

[`DynamoDB.Client`]:
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html

[`DynamoDB.Table`]:
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb/table/index.html

- [Learn boto3]

[Learn boto3]:
    https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/programming-with-python.html

#### JavaScript

To invoke the API from the website, generate an SDK from the API Gateway stage
and use the provided functions to make requests. Use the developer console in
your browser to view the requests from your site and the responses from your
API. CORS can make this setup a bit tricky, but API Gateway provides an Enable
CORS option that handles the necessary configuration automatically.

### 7. pytests

Up to this point, all Lambda code had been written, tested, and deployed
directly through the AWS Console. Using a testing framework such as [pytest]
requires developing locally, so I had to transition away from the online
console. Also, without any infrastructure as code (Terraform), deploying
updates to AWS isn't possible. Luckily, running and testing Lambda can be done
completely offline with the mock boto3 library: moto.

[pytest]:
    https://docs.pytest.org/en/stable/

While reading about how to use [moto for unit testing], I learned that
passing in a table object to each function, instead of a global
variable, makes testing much simpler. This isolates each function from the
rest of the code and makes passing mock tables easy. I recommend a wrapper
class for resource tables to make the code cleaner and more organized.

[moto for unit testing]:
    https://aws.amazon.com/blogs/devops/unit-testing-aws-lambda-with-python-and-mock-aws-services/

#### Fixtures and Parameterization

In my experience, the Pytest documentation can feel a bit scattered, so I
wanted to highlight and clarify two particularly useful features.

[Fixtures] are setup functions that run automatically when a test function
includes an argument with the same name. They’re especially helpful for
initializing mock AWS resources.

[Fixtures]: https://docs.pytest.org/en/stable/how-to/fixtures.html

[Parameterized fixtures and tests] allow multiple sets of arguments to be
passed into a single test or fixture, enabling the same test to run under
different conditions. You can create a single set for all parameters or a set
per each. The latter will run the test with every combination of parameters:

[Parameterized fixtures and tests]: https://docs.pytest.org/en/stable/how-to/parametrize.html#parametrize-basics

```py
import pytest

# Tests [(0,9), (0,8), (0,7), (1,9), (1,8), (1,7), (2,9), (2,8), (2,7)]
@pytest.mark.parametrize("a", [9, 8, 7])
@pytest.mark.parametrize("b", [0, 1, 2])
def test_eval(a, b):
    assert a + b == b + a
```

[Indirect parameterization] is used to pass parameters to a fixture. I used
this to change the setup of mock tables.

[Indirect parameterization]:
    https://docs.pytest.org/en/stable/example/parametrize.html#indirect-parametrization

#### Python Virtual Environment

I configured a [Python virtual environment] to run [pytest-watch] on
startup, which automatically runs tests when a source file is saved. Using
[pytest-xdist] makes it possible to run tests in parallel, speeding up test
times. Configuration of a `pytest.ini` is needed to use pytest-xdist
automatically when pytest-watch invokes the pytests.

[Python virtual environment]:
    https://realpython.com/python-virtual-environments-a-primer/

[pytest-watch]:
    https://pypi.org/project/pytest-watch/

[pytest-xdist]:
    https://pypi.org/project/pytest-xdist/

```ini
# pytest.ini

[pytest]
addopts = -n auto --disable-warnings
```

> [!TIP]
> To autorun tests in a new terminal when the virtual environment is activated,
> add `gnome-terminal -- bash -c "ptw --ext=.py,.json"` to the
> venv/bin/activate file.

### 8. Terraform

This was probably my favorite part of the project. It's a great combination of
a scavenger hunt and problem solving. I converted each existing AWS resource
into its corresponding terraform configuration. The AWS CLI commands are
amazing for gathering the required details for Terraform definitions. For
example, the [`aws apigateway get-method`] command returns the data needed for
defining the Terraform [`aws_api_gateway_method`] resource. Read over the
[Terraform getting-started page] on the official CRC GitHub for a general
overview and guidance.

[`aws apigateway get-method`]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

[`aws_api_gateway_method`]:
    https://awscli.amazonaws.com/v2/documentation/api/latest/reference/apigateway/get-method.html

[Terraform getting-started page]:
    https://github.com/cloudresumechallenge/projects/blob/main/projects/terraform/getting-started.md

If you have zero Terraform experience like I did, Rahul Wagh has a fantastic
video on [how to create a Lambda function in Terraform], which cleared up a
lot of confusion.

[how to create a Lambda function in Terraform]:
    https://www.youtube.com/watch?v=JSR7U700h0U

- [Terraform AWS documentation]
- [Built-in functions] (`jsonencode`, `sha1`, and `join`)
- [Absolute paths]
- [Storing secrets]

[Terraform AWS documentation]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs

[Built-in functions]:
    https://developer.hashicorp.com/terraform/language/functions

[Absolute paths]:
    https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info

[Storing secrets]:
    https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables#set-values-with-a-tfvars-file

#### Reliable Change Detection for External Files

While the Terraform state file does a great job tracking changes within
Terraform files, a bit more effort is needed when working with external files.
There are a few issues with relying on Terraform's state for managing external
changes:

1. Updates to resources triggered by external changes need to occur _before_
   the apply phase, or Terraform won’t detect them. This causes the state file
   to fall out of sync with the live  infrastructure, requiring another `plan`
   and `apply` to reconcile the difference.

2. Terraform doesn't have a consistent way to detect changes for multiple files
   across different environments. Natively, Terraform can only compute a hash
   for a single file. A common workaround is to bundle multiple files into a
   zip and hash that instead. However, zips are highly inconsistent across
   environments due to differences in metadata, file ordering, and compression.
   This causes perpetual state changes between local development and GitHub
   Actions.

To solve this, I wrote a Bash script based on a tutorial on [how to calculate
an MD5 checksum of a directory] in a way that’s consistent across environments.
I then used Terraform’s [`external`] data source to invoke the script during
the plan phase, enabling Terraform to track changes across multiple files
reliably and deterministically.

[how to calculate an MD5 checksum of a directory]:
    https://www.baeldung.com/linux/directory-md5-checksum

[`external`]:
    https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external

#### Remote State

Terraform maintains a state file that maps real-world infrastructure to your
configuration and records associated metadata. For CI/CD, changes to the
state need to be shared across local development and GitHub Actions. Setup of a remote state is incredibly straightforward with the use of an
[S3 backend].

[S3 backend]: https://developer.hashicorp.com/terraform/language/backend/s3

[external]:
    https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external

#### Resource Tips

For Lambda, utilize the [`source_code_hash`] argument to trigger a rebuild
whenever the Python code changes and remember to create an
[`aws_lambda_permission`] resource to give API Gateway permission to invoke
Lambda.

[`source_code_hash`]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#source_code_hash-1

[`aws_lambda_permission`]:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

For API Gateway, remember to take care of the SDK generation. I used the
[`terraform_data`] resource to run a bash shell script to update the
JavaScript files.

[`terraform_data`]:
    https://developer.hashicorp.com/terraform/language/resources/terraform-data

### 9. Source Control

All version control was handled using Git and GitHub. While the project guide
recommends maintaining separate repositories for the frontend and backend, I
chose to use a single repository. To me, this is one cohesive project, not
two, and managing it in a monorepo makes it easier to track changes and keep
everything in sync.

### 10. CI/CD With GitHub Actions

GitHub Actions enables automated testing and deployment workflows. I used it to
run pytest and Terraform commands after changes are pushed to the repository.
To get started, check out the [GitHub Actions overview] to understand how
workflows are structured. From there, it's mostly about learning the YAML
syntax and exploring useful actions and integrations. Github also has a
tutorial on [how to build and test Python] that helped me get started with some
hands-on practice. Using AWS from Terraform requires credentials. Follow this
tutorial to learn [how to configure OpenID Connect between GitHub Actions and
AWS].

[GitHub Actions overview]:
    https://docs.github.com/en/actions/about-github-actions/understanding-github-actions

[how to build and test Python]:
    https://docs.github.com/en/actions/use-cases-and-examples/building-and-testing/building-and-testing-python

[how to configure OpenID Connect between GitHub Actions and AWS]:
    https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/

To my massive disappointment, workflows can _only_ be ran or tested after
pushing code to GitHub. This makes testing and learning slow and repetitive
since you end up making tons of commits just to debug a single workflow.
[`act`] is a commandline tool that lets you run GitHub Actions locally for
faster feedback and less repetition. While there’s a fair amount of
configuration needed to get it behaving like the real GitHub Actions
environment, I think it’s totally worth it. I ran into a few bugs that would
have been much harder to catch without `act`'s detailed, verbose output.

[`act`]: https://nektosact.com/introduction.html

A few tips:

- You'll need to create a Docker image that has the AWS CLI installed to run
  AWS commands.
- Commands may output twice. Use `--quiet` to stop `act` from printing what a
  command has already printed.
- Every time `act` runs, it copies your local Git repo. Any file modifications
  inside the container will be discarded when it finishes. However, remote
  changes, like updates to your Terraform backend or commits to GitHub, do
  persist. Keep that in mind while testing.
- `act` cannot use OIDC to get credentials. You'll have to use your local SSO
  credentials to use AWS.
- Remember to set identical environment variables in `act` and in GitHub.
- Terraform variables can be set with `TF_VAR_example_var` in the workflow.

Check out my bash script for an idea of what options are needed to run `act`:

```sh
#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)

cd "${git_root}"

act push \
--action-offline-mode \
-P ubuntu-24.04=my-act-aws-image \
-W "${git_root}/.github/workflows/run_terraform.yaml" \
--secret-file "${git_root}/act/inputs/.secrets" \
--env-file "${git_root}/act/inputs/.env" \
--var-file "${git_root}/act/inputs/.vars" \
--artifact-server-path "${git_root}/act/artifacts"
```

## Conclusion

This project was a deep dive into cloud engineering, infrastructure as code,
and CI/CD automation. From provisioning AWS resources with Terraform to setting
up robust pipelines with GitHub Actions, each step presented new challenges
that expanded my skills and knowledge.

Throughout this journey, I strengthened my technical expertise in cloud
engineering, DevOps practices, scripting, and testing—laying a solid foundation
for my long-term goal of becoming a DevOps Engineer. I also refined my ability
to quickly learn, adapt to new challenges, and manage multiple responsibilities
effectively.

If you're working on the Cloud Resume Challenge or exploring similar projects,
I hope this write-up helps. Feel free to explore the repo, fork it, or reach
out if you have questions or feedback.

Thanks for reading!
