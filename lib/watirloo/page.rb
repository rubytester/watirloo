module Watirloo

  # Semantic Page Objects Container
  # Page containes interfaces to Objects of Interest on the Web Page
  # Each object defined by key, value pair,
  # Each object defined by key, value pair, 
  # Keys is a friendly name, recognizable name given by the domain object model.
  # Some name that is meaningful to the customer.
  # The value of the interface definiton is a Watir object address in the dom container.
  # The Page class acts as an Adapter between the Business Domain naming of things and Document Object Model naming of elments.
  # It strives to adapt Human Readable tests to Machine Executable code
  class Page

    ## Page Eigenclass
    class << self

      # watir methods are container.method(how, what, value)
      # if how is optional then value can not be there: 
      # for example radio_group('nameofradio') # => implicitly this is a :name, 'nameofradio'
      def make_watir_method(facename, definition) # :nodoc:
        watirmethod, how, what, value = *definition
        #log.debug "make_watir_method: #{facename}, watir: #{watirmethod.inspect} how: #{how.inspect}, what: #{what.inspect}, value: #{value.inspect}"
        if what == nil #if what is nil pass how as what
          #log.debug "making interface: #{facename} => #{watirmethod}('#{how}')"
          class_eval "def #{facename}
                        dombase.#{watirmethod}('#{how}')
                      end"
        else
          extra = value ? ", '#{value}'" : nil # does watir api require a value parameter
          #log.debug "making interface: #{facename} => #{watirmethod}(:#{how}, '#{what}'#{extra})"
          class_eval "def #{facename}
                        dombase.#{watirmethod}(:#{how}, '#{what}'#{extra})
                      end"
        end
      end
      
      def make_watir_methods(definitions) # :nodoc:
        self.faces.update definitions
        definitions.each_pair do |facename, definition|
          make_watir_method(facename, definition)
        end
      end
        
    
      # Declares Semantic Interface to the DOM elements on the Page 
      #   face :friendlyname => [watirelement, how, what]
      # Each interface or face is an object of interest that we want to access by its interface name
      # example:
      #   class GoogleSearch < Watirloo::Page
      #     face :query => [:text_field, :name, 'q]
      #     face :search => [:button, :name, 'btnG']
      #  end
      # each face is a key declared by a semantic symbol that has human meaning in the context of a usecase
      # each value is an array defining access to Watir [:elementType, how, what]
      def face(definitions)
        if definitions.kind_of? Hash
          make_watir_methods(definitions)
        else
          #log.error "Ooops: interface defintion expected to be a Hash, example: face :key => [:text_field, :name, 'name']"
          raise ::Watir::Exception::WatirException, "Wrong arguments for Page Object definition"
        end
      end
      
    end # eigenclass
    
    attr_accessor :interfaces, :dombase
    
    # by convention the Page just attaches to the first available browser.
    # the smart thing to do is to manage browsers existence on the desktop separately
    # and supply Page class with the instance of browser you want for your tests.
    # &block is the convenience at creation time to do some work.
    # example:
    #   browser = Watir::start("http://mysitetotest")
    #   page = Page.new(browser) # specify browser instance to work with or
    #   page = Page.new # just let the page do lazy thing and attach itself to browser.
    # part of this page initialization is to provide a convenience while developing tests where
    # we may have only one browser open and that's the one browser were we want to talk to.
    # this provides simplicity for those who are just starting with Watirloo
    def initialize(browser = Watirloo.browser , &blk)
      @b = browser
      yield browser if block_given? # allows the shortcut to do some work at page creation
    end
    
    # hold reference to the Watir::Browser
    def browser
      @b
    end
    
    # hold reference to the Container used as DOM base for our elements.
    # for example when you work fith frames and the dom you want to act on is in 
    # browser.frame(framename)
    # by default domabase it the current browser assuming it does not have any frames
    def dombase
      @dombase ||= browser #browser by default
    end
          
    def create_interfaces # :nodoc:
      @faces = self.class.faces.dup # do not pass reference, only values
    end
    
    # enter values on controls idenfied by keys on the page.
    # data map is a hash, key represents the page object,
    # value represents its value to be set, either text, array or boolean
    def spray(dataMap)
      dataMap.each_pair do |facename, value|
        get_face(facename).set value #make every element in the dom respond to set to set its value
      end
    end
    
    # set values on the page given the interface keys
    alias set spray 
  
    # return Watir object given by its semantic face symbol name
    def get_face(facename) 
      if self.respond_to? facename # if there is a defined wrapper method for page element provided
        return self.send(facename) 
      else
        raise ::Watir::Exception::WatirException, 'Unknown Semantic Facename'
      end
    end
    
    # Delegate execution to browser if no method or face defined on page class
    def method_missing method, *args
      if dombase.respond_to?(method.to_sym)
        return dombase.send(method.to_sym, *args)
      else
        raise ::Watir::Exception::WatirException, "Browser does not respond to method: #{method.inspect}"
      end
    end
  end

end