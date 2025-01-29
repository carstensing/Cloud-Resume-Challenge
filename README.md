# Cloud Resume Challenge <!-- omit from toc -->

The [**Cloud Resume Challenge**][cloud_resume_challenge] is a multi-step
project designed to help aspiring cloud developers gain real-world **experience
with cloud** technologies by building and deploying a **personal resume website**.

This repo showcases my journey through challenge and what I **learned** along
the way.

**Check out my website at [carsten-singleton.com][my-website].**

[my-website]:
    https://carsten-singleton.com

[cloud_resume_challenge]:
    https://forrestbrazeal.com/2020/04/23/the-cloud-resume-challenge/

## Contents <!-- omit from toc -->

- [Introduction](#introduction)
[Why I Took the Cloud Resume Challenge](#why-i-took-the-cloud-resume-challenge)
    - [What is the Cloud Resume Challenge?](#what-is-the-cloud-resume-challenge)
- [Steps I Took](#steps-i-took)
    - [AWS Certification](#aws-certification)
    - [Hugo Static Site](#hugo-static-site)
    - [AWS Organization](#aws-organization)
        - [Account Protection](#account-protection)
        - [IAM Roles and Policies](#iam-roles-and-policies)
        - [Free Tier](#free-tier)
        - [SSO Login](#sso-login)
    - [S3, HTTPS and DNS](#s3-https-and-dns)
    - [AWS CLI](#aws-cli)
    - [DynamoDB, Lambda, API Gateway and JavaScript](#dynamodb-lambda-api-gateway-and-javascript)
    - [Tests](#tests)
    - [Terraform](#terraform)
    - [Source Control](#source-control)
- [Technology learned](#technology-learned)
- [Technology Used](#technology-used)

## Introduction

### Why I Took the Cloud Resume Challenge

#### Getting a Tech Job

The entry-level job market for software engineers is **oversaturated** and
**highly competitive**. To become **more marketable** and give my career a
**clear direction**, I needed to **refine and specialize** my skill set.

At home, I enjoy IT-type work like, building computers, playing
with microcontrollers, and tinkering with Linux. I also love the creativity and
problem-solving of writing code. I've found that the specialization that
bridges the gap between these two is **DevOps**.

**DevOps** is a set of practices that combines **software development** and
**IT operations** to improve the speed and reliability of delivering
applications. It emphasizes collaboration, **automation, continuous integration
and deployment (CI/CD), monitoring**, and feedback loops to enhance efficiency,
**security**, and quality across the development lifecycle.[^devops_handbook]

[^devops_handbook]: The DevOps Handbook: How to Create World-Class Agility,
    Reliability, & Security in Technology Organizations

#### So why become a Cloud Engineer?

**Cloud Engineering** is an **excellent starting point for DevOps** because it
provides hands-on experience with automation, Infrastructure as Code (IaC), and
cloud-native technologies. Cloud engineers work with tools like Terraform,
CI/CD pipelines, and container orchestration (Docker, Kubernetes), all of
which are essential in DevOps. They also gain experience in monitoring,
security, and scalability, key principles in DevOps workflows. Since cloud
engineers collaborate closely with **development and operations** teams,
transitioning into a DevOps role becomes a natural progression.

### What is the Cloud Resume Challenge?

The [**Cloud Resume Challenge**][cloud_resume_challenge], by [Forrest
Brazeal][forrest_brazeal], is a high-level guide that walks cloud development
from end-to-end and culminates in a personal resume website. For my
implementation, I chose to use [Amazon Web Services][aws].

[forrest_brazeal]:
    https://forrestbrazeal.com/

[aws]:
    https://aws.amazon.com/what-is-aws/

Here is the general outline:

- **Certification**: Obtain a cloud certification (AWS Certified Cloud
  Practitioner).

- **Frontend**: Create a static website (HTML, CSS, JavaScript) and host it
  using a cloud provider (S3, Route53, Cloudfront).

- **Backend**: Implement a visitor counter using a serverless function and a
  database(Lambda, DynamoDB, API Gateway).

- **Infrastructure as Code (IaC)**: Automate deployments with tools like
  Terraform or AWS CloudFormation.

- **CI/CD**: Set up automated testing (PyTest, PlayWright) and deployment
  pipelines (GitHub Actions).

## Steps I Took

### AWS Certification

With basically zero cloud experience starting out, studying for the AWS
Certified Cloud Practitioner exam gave me the foundation I needed for the Cloud
Resume Challenge. I easily spent over 60 hours studying, which includes doing
over 1900 practice problems.

Free resources that I used to pass the exam (Oct 2024):

- [Andrew Brown's lecture videos][lecture]
- [Sthithapragna's practice questions][questions]

Make sure you study material is up to date with the current version of the exam
and exam outline. I studied old material without realizing and this set me back
some time.

[lecture]:
    https://www.youtube.com/watch?v=NhDYbskXRgc&list=LL&index=11
[questions]:
    https://www.youtube.com/playlist?list=PL7GozF-qZ4KeQftuqU3yxvQ-f3eFNUiuJ

### Hugo Static Site

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

### AWS Organization

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

As I moved from one service to another, I found what permissions I was lacking.
Following the principle of least privilege, I added only the permissions
required for each specific task. This incremental approach helped me learn how
services use IAM roles and policies, and how they impact development on AWS.

#### Free Tier

The hack to creating member accounts is to use email sub-addressing instead of
creating a new email. For example, if the root email is myemail@mail.com, the
dev account can be created with myemail+dev@mail.com. Even if the root account
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

[sso_for_personal_development]:
    https://dev.to/aws-builders/minimal-aws-sso-setup-for-personal-aws-development-220k

### S3, HTTPS and DNS

I purchased a domain name through Route 53 and created an S3 bucket to store my
website files built by Hugo. Make sure the hosted zone's name servers match
where traffic is being routed. I spent a lot of time trying to figure out why
DNS wasn't working because of this. After that, I used CloudFront to enable
HTTPS. AWS has tutorials on how to do all of this, which made it very easy.

Learning Resources:

- [Configuring a static site using a custom domain registered with Route 53][s3_static_site_custom_domain]

- [CloudFront and HTTPS][s3_static_site_cloudfront_and_https]

[s3_static_site_custom_domain]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html

[s3_static_site_cloudfront_and_https]:
    https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-cloudfront-walkthrough.html

### AWS CLI

TODO

### DynamoDB, Lambda, API Gateway and JavaScript

I learned a **ton** on this chuck of the project. I understood the concept of
how a website, a database and an API interacted, but actually building it all
really challenged me.

### Tests

https://aws.amazon.com/blogs/devops/unit-testing-aws-lambda-with-python-and-mock-aws-services/
https://docs.pytest.org/en/stable/example/parametrize.html#indirect-parametrization

### Terraform

### Source Control

## Technology learned

- [AWS CLI][aws_cli]
- [Hugo][hugo]
- [PyTest][pytest]
- [PlayWright for Python][playwright_for_python]
- [Terraform][terraform]

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

## Technology Used

- Git
- Github
- VSCode
- Ubuntu
- Firefox and Chrome Developer Tools

## Outline

```markdown
# My Journey Through the Cloud Resume Challenge  

## Introduction  
- Why I took on the Cloud Resume Challenge  
- My background and goals  
- What this post will cover  

## What is the Cloud Resume Challenge?  
- Overview of the challenge  
- Key skills and technologies involved  
- Why it's a great project for cloud learners  

## Tech Stack and Tools Used  
- Cloud provider (e.g., AWS)  
- Frontend (HTML, CSS, JavaScript)  
- Backend (API, AWS Lambda, DynamoDB)  
- Infrastructure as Code (Terraform, CloudFormation)  
- CI/CD (GitHub Actions, AWS CodePipeline)  

## Step-by-Step Breakdown  
### Setting Up the Frontend  
- Creating the resume website  
- Hosting it on AWS S3  
- Adding a custom domain and HTTPS  

### Building the Backend  
- Implementing the visitor counter API  
- Using AWS Lambda and DynamoDB  
- Ensuring security and best practices  

### Automating with CI/CD  
- Setting up GitHub Actions for deployment  
- Writing tests and automating infrastructure deployment  

## Challenges and Lessons Learned  
- Difficulties I faced and how I overcame them  
- Key takeaways from the experience  

## Results and Next Steps  
- Showcasing the final resume website  
- Plans for further learning and improvements  

## Conclusion  
- Reflections on the overall journey  
- Encouragement for others to take on the challenge  
- Call to action (e.g., connect with me, check out my GitHub)  
```