module Watirloo

  # Semantic Page Objects Container
  # include it in your ClientClass that manages Test. Your client class must provide an instance of browser.
  # If you don't want an explicit browser the Watirloo.browser will be used.
  # example
  #     class UsageScenarioOfSomeFeature
  #       include Watirloo::Page
  #     end
  # now the client GoogleSearch can access browser and elements defined
  # instead of including it directly in classes that you instantiate to keep track of state you can build modules of pages
  # that you can later include into your client
  module Page

    # provide browser for a client. If now browser is assigned to a client
    # Use the default Watirloo.browser if no browser set explicitly
    def browser
      @browser ||= ::Watirloo.browser
    end

    # set browser instance for a client to use
    # --
    # the method is a bit better than browser= because setting browser in mehtods would probably
    # requires a call to:
    #   self.browser= ie
    # else
    #   browser = ie
    # may be an assignemnt to local variable
    def browser=(browser)
      @browser = browser
    end

    # browser document container that delimits the scope of elements.
    # all faces use page as a base. In a frameless DOM the browser is page, the document container.
    # however if page with frames you can setup a doc destination to be a frame as the
    # base container for face accessors.
    # in most circumstances page is a passthru to browser
    # example: if you have a frameset and you want to talk to a frame(:name, 'content') you can redefine
    # set the page
    # self.page = browser.frame(:name, 'content') see set_page
    #
    def page
      @page ||= browser
    end

    # set the page base element as the receiver of all facename methods
    # one would have to make this type of call:
    #   self.page = watir_element
    #   else this:
    #   page = watir_element
    #   may be treated as assignemnt to local variable
    #
    def page=(watir_element)
      @page = watir_element
    end

    module ClassMethods

      # "anything which is the forward or world facing part of a system
      # which has internal structure is considered its 'face', like the facade of a building"
      # ~  http://en.wikipedia.org/wiki/Face
      #
      # Declares Semantic Interface to the DOM elements on the Page (facade) binds a symbol to a block of code that accesses the DOM.
      # When the user speaks of filling in the last name the are usually entering data in a text_field
      # we can create a semantic accessor interface like this:
      #   face(:last_name) { text_field(:name, 'last_nm'}
      # what matters to the user is on the left (:last_name) and what matters to the programmer is on the right
      # The face method provides an adapter and insolates the tests form the changes in GUI.
      # The patterns is: face(:friendlyname) { watir_element(how, whatcode }
      # where watir_element is actuall way of accessing the element on the page. The page is implicit.
      # Each interface or face is an object of interest that we want to access by its interface name
      #   example:
      #
      #     class GoogleSearch
      #       include Watirloo::Page
      #       face(:query)   { text_field(:name, 'q') }
      #       face(:search)  { button(:name, 'btnG') }
      #     end
      #
      #     at run time calling
      #     query.set "Ruby"
      #     is equivalent to
      #     page.text_field(:name, 'q').set "Ruby"
      #     where page is the root of HTML document
      #
      def face(name, *args, &definition)
        define_method(name) do |*args|
          page.instance_exec(*args, &definition)
        end
      end

    end

    # metahook by which ClassMethods become singleton methods of an including module
    # Perhaps the proper way is to do this
    # class SomeClass
    #   include PageHelper
    #   extend PageHelper::ClassMethods
    # end
    # but we are just learning this metaprogramming
    def self.included(klass)
      klass.extend(ClassMethods)
    end
  
    # enter values on controls idenfied by keys on the page.
    # data map is a hash, key represents the page objects that can be filled or set with values,
    # value represents its value to be set, either text, array or boolean
    # exmaple: 
    #     spray :first => "Johnny", :last => 'Begood'
    #     
    #     # Given the faces defined
    #     face(:first) {doc.text_field(:name, 'lst_nm')}
    #     face(:last) {doc.text_field(:name, 'fst_nm')}
    def spray(hash)
      hash.each_pair do |facename, value|
        self.send(facename).set value #make every control element in watir respond to set
      end
    end

    # set values on the page given the interface keys
    alias set spray


    def scrape(facenames)
      data = {}
      facenames.each do |facename|
        watir_control = self.send facename
        method_name = case watir_control.class.to_s.split("::").last
        when "SelectList", "CheckboxGroup", "RadioGroup" then :selected
        else  
          :value
        end
        data.update facename => watir_control.send(method_name)
      end
      data
    end


  end
end