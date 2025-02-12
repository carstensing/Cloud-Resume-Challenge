+++
date = "2024-10-17T14:55:59-07:00"
draft = true
title = "Cloud Resume Challenge [Draft]"
summary = """A work in progress."""
+++

The [**Cloud Resume Challenge**][cloud_resume_challenge] is a multi-step
project designed to help aspiring cloud developers gain real-world experience
with cloud technologies by building and deploying a **personal resume
website**.

This repo showcases my journey through the challenge and what I learned along
the way.

**Check out my website at [carsten-singleton.com][my-website].**

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

[forrest_brazeal]:
    https://forrestbrazeal.com/

[aws]:
    https://aws.amazon.com/what-is-aws/

This is the general outline:

- **Certification**: Obtain a cloud certification (AWS Certified Cloud
  Practitioner).

- **Frontend**: Create a static website (HTML, CSS, JavaScript) and host it
  using a cloud provider (S3, Route53, Cloudfront).

- **Backend**: Implement a visitor counter using a serverless function and a
  database (Lambda, DynamoDB, API Gateway).

- **Infrastructure as Code (IaC)**: Automate deployments with tools like
  Terraform or AWS CloudFormation.

- **CI/CD**: Set up automated testing (PyTest, PlayWright) and deployment
  pipelines (GitHub Actions).

Forrest Brazeal has a project guide that details the best ways to go about the
challenge and includes additional modifications for even more hand-on practice.
I used

<https://cloudresumechallenge.dev/book/>

## Steps I Took

### AWS Certification

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

[certified_cloud_practitioner]:
    https://aws.amazon.com/certification/certified-cloud-practitioner/

[certified_solutions_architect]:
    https://aws.amazon.com/certification/certified-solutions-architect-professional/

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

### AWS Organizations

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

TODO

### Tests

TODO

### Terraform

TODO

### Source Control

TODO

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
- Firefox Developer Tools
