# automated-backups - roadmap.sh challenge

https://roadmap.sh/projects/automated-backups

The goal of this project is to set up a scheduled workflow that back up a MongoDB database every 12 hours and upload the backup to S3 compatible object storage.

This project uses systemd timer to schedule the backup, with DigitalOcean Spaces as the storage destination.

The configuration is stored as Infrastructure as Code in the GitHub repository and is executed in a GitHub Actions pipeline.

This is a great exercise for any System Admin, Platform Engineer, or DevOps professional to take on. It provides an excellent opportunity to expand the project with personal stretch goals and further enhance skills.

# Terraform

The terraform stack is pretty basic, it provisions a virtual machine with 1CPU and 1GB of RAM running the latest LTS release of Ubuntu. It also creates a backup bucket in digital ocean Spaces Object Storage.
To integrate with a GitHub Actions pipeline, a cloud state backend is used.

# Ansible

To retrieve hosts for Ansible, a dynamic inventory with DigitalOcean plugin is used. This approach is ideal for environments where servers are dynamically provisioned. Tags are used to filter machines. The playbook follows a role-based structure to set up resources, The following roles are created and tagged accordingly:

- base
- mongo
- mongo-backup-service
- wikipedia-mongodb-seeder

Tagging is crucial for integration with the GitHub Actions pipeline. To optimize performance, I chose to run the playbook in the pipeline only for roles that have changed, reducing execution time. I find that Ansible can be slow for quick iterations, so this helps speed up deployments.

The backup service requires secrets, so I decided to use **systemd-creds** to store encrypted secrets directly in the service unit file. The secrets are stored in Github repository secrets and Ansible retrieves them from Env variables. In a later step, the unit file receives the encrypted secrets using a Jinja template.

```yaml
- name: Encrypt secret
  community.general.systemd_creds_encrypt:
    name: do_access_secret
    pretty: true
    secret: >
      {{ {
          'id': lookup('ansible.builtin.env', 'DO_SPACES_ACCESS_ID') ,
          'key': lookup('ansible.builtin.env', 'DO_SPACES_ACCESS_KEY')
      } | to_json }}
  register: do_access_secret
```

# GitHub Actions

The pipeline consists of three jobs:

- changes
- terraform
- ansible

It extensively uses **dorny/paths-filter** to minimize execution time by skipping unnecessary steps. First, the **changes** job checks if there were any changes in Terraform or Ansible code. This determines whether the Terraform and Ansible jobs should run or be skipped.

The Ansible job includes its own **dorny/paths-filter** step to identify which roles to execute or skip, significantly reducing execution time.

## Skipping Jobs Using Paths-Filter

In simple cases, skipping a job or step based on paths-filter is straightforward:

```yaml
if: ${{ steps.filter.outputs.roles == 'true' }}
```

However, when specific behaviour is required, the condition becomes more complex. In the example below, the Ansible job runs only if any Ansible files have changed or the Terraform job has been **skipped or successfully completed**. This ensures that Ansible always runs after Terraform, **even if** Terraform is skipped.

```yaml
ansible:
  needs:
    - changes
    - terraform
  if: >-
    ${{
      (always() && (needs.terraform.result == 'success' || needs.terraform.result == 'skipped') && needs.changes.outputs.ansible == 'true' )
    }}
```

## Determining Changed Roles

To decide which roles to execute, a jq command extracts role names from the modified file paths variable. The result is then set as a step output:

```
- name: Get changed roles
  id: roles
  if: ${{ steps.filter.outputs.roles == 'true' }}
  run: |
    changed_roles=$(echo '${{ steps.filter.outputs.roles_files }}' | jq -r '[.[] | split("/")[2]] | sort | unique | join(",")')
    echo "Changed roles: $changed_roles"
    echo "changed_roles=$changed_roles" >> $GITHUB_OUTPUT
```

# Data seeder script

To populate MongoDB with meaningful data, a Python script is used. It utilizes wikipediaapi to retrieve article data from Wikipedia and pymongo to insert it into the database. The script is then run on the remote server:

```
(venv) ubuntu@srv:~/wikipedia-mongodb-seeder$ python script.py
Inserted 3 Wikipedia articles into the collection.
```

<details>
  <summary>
    Result in the mongodb
  </summary>
  
  ```
  (venv) ubuntu@srv:~/wikipedia-mongodb-seeder$ python check_data.py 
  Databases: ['admin', 'config', 'local', 'wikipedia']
  Collections in wikipedia : ['wikipedia_data']
  Documents in wikipedia_data :
  {'_id': ObjectId('67cc952b727b8d0526c37ce0'),
  'categories': ['Category:All Wikipedia articles written in American English',
                  'Category:All articles containing potentially dated statements',
                  'Category:Articles containing potentially dated statements '
                  'from 2008',
                  'Category:Articles containing potentially dated statements '
                  'from 2020',
                  'Category:Articles containing potentially dated statements '
                  'from December 2022',
                  'Category:Articles containing potentially dated statements '
                  'from February 2025',
                  'Category:Articles containing potentially dated statements '
                  'from October 2024',
                  'Category:Articles with example Python (programming language) '
                  'code',
                  'Category:Articles with short description',
                  'Category:CS1: unfit URL',
                  'Category:Class-based programming languages',
                  'Category:Computer science in the Netherlands',
                  'Category:Concurrent programming languages',
                  'Category:Cross-platform free software',
                  'Category:Cross-platform software',
                  'Category:Dutch inventions',
                  'Category:Dynamically typed programming languages',
                  'Category:Educational programming languages',
                  'Category:High-level programming languages',
                  'Category:Information technology in the Netherlands',
                  'Category:Monty Python references',
                  'Category:Multi-paradigm programming languages',
                  'Category:Notebook interface',
                  'Category:Object-oriented programming languages',
                  'Category:Pages using Sister project links with hidden '
                  'wikidata',
                  'Category:Pages using Sister project links with wikidata '
                  'namespace mismatch',
                  'Category:Pattern matching programming languages',
                  'Category:Programming languages',
                  'Category:Programming languages created in 1991',
                  'Category:Python (programming language)',
                  'Category:Scripting languages',
                  'Category:Short description matches Wikidata',
                  'Category:Text-oriented programming languages',
                  'Category:Use American English from December 2024',
                  'Category:Use dmy dates from November 2021'],
  'summary': 'Python is a high-level, general-purpose programming language. Its '
              'design philosophy emphasizes code readability with the use of '
              'significant indentation.\n'
              'Python is dynamically type-checked and garbage-collected. It '
              'supports multiple programming paradigms, including structured '
              '(particularly procedural), object-oriented and functional '
              'programming. It is often described as a "batteries included" '
              'language due to its comprehensive standard library.\n'
              'Guido van Rossum began working on Python in the late 1980s as a '
              'successor to the ABC programming language and first released it '
              'in 1991 as Python 0.9.0. Python 2.0 was released in 2000. Python '
              '3.0, released in 2008, was a major revision not completely '
              'backward-compatible with earlier versions. Python 2.7.18, '
              'released in 2020, was the last release of Python 2.\n'
              'Python consistently ranks as one of the most popular programming '
              'languages, and has gained widespread use in the machine learning '
              'community.',
  'title': 'Python (programming language)',
  'url': 'https://en.wikipedia.org/wiki/Python_(programming_language)'}
  {'_id': ObjectId('67cc952b727b8d0526c37ce1'),
  'categories': ['Category:Agile software development',
                  'Category:Articles with short description',
                  'Category:CS1 maint: location missing publisher',
                  'Category:CS1 maint: multiple names: authors list',
                  'Category:Information technology management',
                  'Category:Short description is different from Wikidata',
                  'Category:Software development',
                  'Category:Software development process',
                  'Category:Wikipedia pending changes protected pages'],
  'summary': 'DevOps is the integration and automation of the software '
              'development and information technology operations. DevOps '
              'encompasses necessary tasks of software development and can lead '
              'to shortening development time and improving the development life '
              'cycle. According to Neal Ford, DevOps, particularly through '
              'continuous delivery, employs the "Bring the pain forward" '
              'principle, tackling tough tasks early, fostering automation and '
              'swift issue detection. Software programmers and architects should '
              'use fitness function to keep their software in check.\n'
              'Although debated, DevOps is characterized by key principles: '
              'shared ownership, workflow automation, and rapid feedback.\n'
              'From an academic perspective, Len Bass, Ingo Weber, and Liming '
              'Zhu—three computer science researchers from the CSIRO and the '
              'Software Engineering Institute—suggested defining DevOps as "a '
              'set of practices intended to reduce the time between committing a '
              'change to a system and the change being placed into normal '
              'production, while ensuring high quality".\n'
              'However, the term is used in multiple contexts. At its most '
              'successful, DevOps is a combination of specific practices, '
              'culture change, and tools.',
  'title': 'DevOps',
  'url': 'https://en.wikipedia.org/wiki/DevOps'}
  {'_id': ObjectId('67cc952b727b8d0526c37ce2'),
  'categories': ['Category:All articles needing additional references',
                  'Category:Articles needing additional references from August '
                  '2014',
                  'Category:Articles with short description',
                  'Category:CS1 Portuguese-language sources (pt)',
                  'Category:Planning',
                  'Category:Short description is different from Wikidata',
                  'Category:Technology forecasting'],
  'summary': 'A technology roadmap is a flexible planning schedule to support '
              'strategic and long-range planning, by matching short-term and '
              'long-term goals with specific technology solutions. It is a plan '
              'that applies to a new product or process and may include using '
              'technology forecasting or technology scouting to identify '
              'suitable emerging technologies. It is a known technique to help '
              'manage the fuzzy front-end of innovation. It is also expected '
              'that roadmapping techniques may help companies to survive in '
              'turbulent environments and help them to plan in a more holistic '
              'way to include non-financial goals and drive towards a more '
              'sustainable development. Here roadmaps can be combined with other '
              'corporate foresight methods to facilitate systemic change.\n'
              'Developing a roadmap has three major uses. It helps reach a '
              'consensus about a set of needs and the technologies required to '
              'satisfy those needs, it provides a mechanism to help forecast '
              'technology developments, and it provides a framework to help plan '
              'and coordinate technology developments. It may also be used as an '
              'analysis tool to map the development and emergence from new '
              'industries.',
  'title': 'Technology roadmap',
  'url': 'https://en.wikipedia.org/wiki/Technology_roadmap'}
  ```

</details>

# Backup script

Backup is run every 12 hours using systemd timer. It triggers systemd oneshot service which runs bash script.

The backup process is straighfroward: mongodump command is used with compress and specific archive falgs.

The script uses special variable `${CREDENTIALS_DIRECTORY}` provided by systemd-creds, which stores decrypted secrets during runtime.

To upload the backup to DigitalOcean Spaces Object Storage, the script uses `s3cmd`. Since DigitalOcean Spaces is S3-compatible but not AWS, the `--host` and `--host-bucket` flags are required to specify the correct endpoint.

```shell
#!/usr/bin/env bash
set -euo pipefail

filename="dump-$(date '+%Y%m%d%H%M%S').gz"

mongodump --gzip --archive="${filename}"

export AWS_ACCESS_KEY_ID=$(jq -r '.id' < "${CREDENTIALS_DIRECTORY}/do_access_secret")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.key' < "${CREDENTIALS_DIRECTORY}/do_access_secret")

s3cmd --host="fra1.digitaloceanspaces.com" \
      --host-bucket="%(bucket)s.fra1.digitaloceanspaces.com" \
      put "${filename}" s3://backups-roadmapsh-kzwolenik95/

rm "${filename}"
```
