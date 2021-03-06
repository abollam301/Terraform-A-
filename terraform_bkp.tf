{\rtf1\ansi\ansicpg1252\cocoartf2511
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fnil\fcharset0 Menlo-Regular;\f2\fmodern\fcharset0 Courier;
}
{\colortbl;\red255\green255\blue255;\red203\green35\blue57;\red255\green255\blue255;\red0\green0\blue0;
}
{\*\expandedcolortbl;;\cssrgb\c84314\c22745\c28627;\cssrgb\c100000\c100000\c100000;\cssrgb\c0\c0\c0;
}
\paperw11900\paperh16840\margl1440\margr1440\vieww33400\viewh18660\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 ## Provider will be aws\

\itap1\trowd \taflags1 \trgaph108\trleft-108 \trcbpat3 \trbrdrt\brdrnil \trbrdrl\brdrnil \trbrdrt\brdrnil \trbrdrr\brdrnil 
\clmgf \clvertalt \clshdrawnil \clwWidth2711\clftsWidth3 \clbrdrt\brdrnil \clbrdrl\brdrnil \clbrdrb\brdrnil \clbrdrr\brdrnil \clpadl200 \clpadr200 \gaph\cellx4320
\clmrg \clvertalt \clshdrawnil \clwWidth2711\clftsWidth3 \clbrdrt\brdrnil \clbrdrl\brdrnil \clbrdrb\brdrnil \clbrdrr\brdrnil \clpadl200 \clpadr200 \gaph\cellx8640
\pard\intbl\itap1\pardeftab720\sl400\partightenfactor0

\f1 \cf2 \expnd0\expndtw0\kerning0
\cell 
\pard\intbl\itap1\cell \lastrow\row
\pard\pardeftab720\sl280\partightenfactor0

\f2 \cf4 provider "aws" \{\
    access_key = "$\{var.aws_access_key\}"\
    secret_key = "$\{var.aws_secret_key\}"\
    region = "$\{var.aws_region\}"\
\}\
\
\
## variables for vpc, AMI region,public,private,protected\
\
variable "aws_access_key" \{\}\
variable "aws_secret_key" \{\}\
variable "aws_key_path" \{\}\
variable "aws_key_name" \{\}\
\
variable "aws_region" \{\
    description = "EC2 Region for the VPC"\
    default = "eu-west-1"\
\}\
\
variable "amis" \{\
    description = "AMIs by region"\
    default = \{\
        eu-west-1 = "ami-f1810f86" # ubuntu 14.04 LTS\
    \}\
\}\
\
variable "vpc_cidr" \{\
    description = "CIDR for the whole VPC"\
    default = "10.0.0.0/16"\
\}\
\
variable "public_subnet_cidr" \{\
    description = "CIDR for the Public Subnet"\
    default = "10.0.0.0/24"\
\}\
\
variable "private_subnet_cidr" \{\
    description = "CIDR for the Private Subnet"\
    default = "10.0.1.0/24"\
\}\
\
variable \'93protected_subnet_cidr" \{\
    description = "CIDR for the Protected Subnet"\
    default = "10.0.2.0/24"\
\}\
\
\
## VPC creation, internet gateway, security group, public, private and protected subnets\
\
resource "aws_vpc" "default" \{\
    cidr_block = "$\{var.vpc_cidr\}"\
    enable_dns_hostnames = true\
    tags \{\
        Name = "terraform-aws-vpc"\
    \}\
\}\
\
resource "aws_internet_gateway" "default" \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\}\
\
/*\
  NAT Instance\
*/\
resource "aws_security_group" "nat" \{\
    name = "vpc_nat"\
    description = "Allow traffic to pass from the public subnet to the internet"\
\
    ingress \{\
        from_port = 80\
        to_port = 80\
        protocol = "tcp"\
        cidr_blocks = ["$\{var.public_subnet_cidr\}"]\
    \}\
    ingress \{\
        from_port = 443\
        to_port = 443\
        protocol = "tcp"\
        cidr_blocks = ["$\{var.public_subnet_cidr\}"]\
    \}\
    ingress \{\
        from_port = 22\
        to_port = 22\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    ingress \{\
        from_port = -1\
        to_port = -1\
        protocol = "icmp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
\
    egress \{\
        from_port = 80\
        to_port = 80\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    egress \{\
        from_port = 443\
        to_port = 443\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    egress \{\
        from_port = 22\
        to_port = 22\
        protocol = "tcp"\
        cidr_blocks = ["$\{var.vpc_cidr\}"]\
    \}\
    egress \{\
        from_port = -1\
        to_port = -1\
        protocol = "icmp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    tags \{\
        Name = "NATSG"\
    \}\
\}\
\
resource "aws_instance" "nat" \{\
    ami = "ami-30913f47" # this is a special ami preconfigured to do NAT\
    availability_zone = "eu-west-1a"\
    instance_type = "m1.small"\
    key_name = "$\{var.aws_key_name\}"\
    vpc_security_group_ids = ["$\{aws_security_group.nat.id\}"]\
    subnet_id = "$\{aws_subnet.eu-west-1a-public.id\}"\
    associate_public_ip_address = true\
    source_dest_check = false\
\
    tags \{\
        Name = "VPC NAT"\
    \}\
\}\
\
resource "aws_eip" "nat" \{\
    instance = "$\{aws_instance.nat.id\}"\
    vpc = true\
\}\
\
/*\
  Public Subnet\
*/\
resource "aws_subnet" "eu-west-1a-public" \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    cidr_block = "$\{var.public_subnet_cidr\}"\
    availability_zone = "eu-west-1a"\
\
    tags \{\
        Name = "Public Subnet"\
    \}\
\}\
\
resource "aws_route_table" "eu-west-1a-public" \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    route \{\
        cidr_block = "0.0.0.0/0"\
        gateway_id = "$\{aws_internet_gateway.default.id\}"\
    \}\
\
    tags \{\
        Name = "Public Subnet"\
    \}\
\}\
\
resource "aws_route_table_association" "eu-west-1a-public" \{\
    subnet_id = "$\{aws_subnet.eu-west-1a-public.id\}"\
    route_table_id = "$\{aws_route_table.eu-west-1a-public.id\}"\
\}\
\
/*\
  Private Subnet\
*/\
resource "aws_subnet" "eu-west-1a-private" \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    cidr_block = "$\{var.private_subnet_cidr\}"\
    availability_zone = "eu-west-1a"\
\
    tags \{\
        Name = "Private Subnet"\
    \}\
\}\
\
resource "aws_route_table" "eu-west-1a-private" \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    route \{\
        cidr_block = "0.0.0.0/0"\
        instance_id = "$\{aws_instance.nat.id\}"\
    \}\
\
    tags \{\
        Name = "Private Subnet"\
    \}\
\}\
\
resource "aws_route_table_association" "eu-west-1a-private" \{\
    subnet_id = "$\{aws_subnet.eu-west-1a-private.id\}"\
    route_table_id = "$\{aws_route_table.eu-west-1a-private.id\}"\
\}\
\
\
\
/*\
  Protected Subnet\
*/\
resource "aws_subnet" "eu-west-1a-protected \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    cidr_block = "$\{var.protected_subnet_cidr\}"\
    availability_zone = "eu-west-1a"\
\
    tags \{\
        Name = \'93Protected Subnet"\
    \}\
\}\
\
resource "aws_route_table" "eu-west-1a-protected\'94 \{\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    route \{\
        cidr_block = "0.0.0.0/0"\
        gateway_id = "$\{aws_internet_gateway.default.id\}"\
    \}\
\
    tags \{\
        Name = \'93Protected Subnet"\
    \}\
\}\
\
resource "aws_route_table_association" "eu-west-1a-protected \{\
    subnet_id = "$\{aws_subnet.eu-west-1a-protected.id\}"\
    route_table_id = "$\{aws_route_table.eu-west-1a-protected.id\}"\
\}\
\
\
##Public subnets\
\
/*\
  Web Servers\
*/\
resource "aws_security_group" "web" \{\
    name = "vpc_web"\
    description = "Allow incoming ingress and egress connections for public subnets.\'94\
\
    ingress \{\
        from_port = 80\
        to_port = 80\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    ingress \{\
        from_port = 443\
        to_port = 443\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    ingress \{\
        from_port = -1\
        to_port = -1\
        protocol = "icmp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
\
    egress \{ # SQL Server\
        from_port = 1433\
        to_port = 1433\
        protocol = "tcp"\
        cidr_blocks = ["$\{var.private_subnet_cidr\}"]\
    \}\
    egress \{ # MySQL\
        from_port = 3306\
        to_port = 3306\
        protocol = "tcp"\
        cidr_blocks = ["$\{var.private_subnet_cidr\}"]\
    \}\
\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    tags \{\
        Name = "WebServerSG"\
    \}\
\}\
\
resource "aws_instance" "web-1" \{\
    ami = "$\{lookup(var.amis, var.aws_region)\}"\
    availability_zone = "eu-west-1a"\
    instance_type = "m1.small"\
    key_name = "$\{var.aws_key_name\}"\
    vpc_security_group_ids = ["$\{aws_security_group.web.id\}"]\
    subnet_id = "$\{aws_subnet.eu-west-1a-public.id\}"\
    associate_public_ip_address = true\
    source_dest_check = false\
\
    tags \{\
        Name = "Web Server 1"\
    \}\
\}\
\
resource "aws_eip" "web-1" \{\
    instance = "$\{aws_instance.web-1.id\}"\
    vpc = true\
\}\
\
\
## Private subnets\
\
\
resource "awe_security_group" "db" \{\
    name = "vpc_db"\
    description = "Allow egress connections for private subnets.\'94\
\
    egress \{\
        from_port = 80\
        to_port = 80\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
    egress \{\
        from_port = 443\
        to_port = 443\
        protocol = "tcp"\
        cidr_blocks = ["0.0.0.0/0"]\
    \}\
\
    vpc_id = "$\{aws_vpc.default.id\}"\
\
    tags \{\
        Name = "DBServerSG"\
    \}\
\}\
\
resource "aws_instance" "db-1" \{\
    ami = "$\{lookup(var.amis, var.aws_region)\}"\
    availability_zone = "eu-west-1a"\
    instance_type = "m1.small"\
    key_name = "$\{var.aws_key_name\}"\
    vpc_security_group_ids = ["$\{aws_security_group.db.id\}"]\
    subnet_id = "$\{aws_subnet.eu-west-1a-private.id\}"\
    source_dest_check = false\
\
    tags \{\
        Name = "DB Server 1"\
    \}\
\}\
}
