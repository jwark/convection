require_relative '../resource'
require_relative 'aws_ec2_subnet'

module Convection
  module DSL
    ## Add DSL method to template namespace
    module Template
      def ec2_vpc(name, &block)
        r = Model::Template::Resource::EC2VPC.new(name, self)
        r.instance_exec(&block) if block

        resources[name] = r
      end

      module Resource
        ##
        # DSL For VPC sub-entities
        ##
        module EC2VPC
          def subnet(name, &block)
            s = Model::Template::Resource::EC2Subnet.new("#{ self.name }Subnet#{ name}", @template)
            s.vpc_id(ref(self.name))

            ## Allocate the next available subnet
            @subnet_allocated += 1
            s.network(@network.subnet(
              :Bits => @subnet_length,
              :NumSubnets => @subnet_allocated)[@subnet_allocated - 1])

            s.instance_exec(&block) if block
            @template.resources[s.name] = s
          end
        end
      end
    end
  end

  module Model
    class Template
      class Resource
        ##
        # AWS::EC2::Subnet
        ##
        class EC2VPC < Resource
          include DSL::Template::Resource::EC2VPC
          include Model::Mixin::CIDRBlock
          include Model::Mixin::Taggable

          attribute :subnet_length

          def initialize(*args)
            super

            type 'AWS::EC2::VPC'
            @subnet_allocated = 0
            @subnet_length = 24
          end

          def enable_dns(value)
            property('EnableDnsSupport', value)
            property('EnableDnsHostnames', value)
          end

          def instance_tenancy(value)
            property('InstanceTenancy', value)
          end

          def render(*args)
            super.tap do |resource|
              render_tags(resource)
            end
          end
        end
      end
    end
  end
end
