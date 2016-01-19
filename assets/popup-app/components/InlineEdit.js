import React from 'react';

function SelectInputText(element) {
    element.setSelectionRange(0, element.value.length);
}

class InlineEdit extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            editing: false,
            text: this.props.text,
            hasError: '',
            helpText: ''
        };
          
    }

    startEditing() {
        this.setState({editing: true, text: this.props.text});
    }

    finishEditing(event) {
      this.validate = this.isInputValid;
      let helpText = this.props.helpText;
      if (this.props.validate)
          this.validate = this.props.validate
      else
        helpText = `Text length must be between ${this.props.minLength} and ${this.props.maxLength}`;

      
      if (event)
        event.preventDefault();
      if (this.props.text === this.state.text) {
        this.cancelEditing();
      } else if (!this.validate(this.state.text)) {
        this.setState({
          hasError: 'has-error',
          helpText: helpText
        });
      } else { 
        this.commitEditing();
      } 
    }

    cancelEditing() {
        this.setState({editing: false, text: this.props.text});
    }

    commitEditing() {
        this.setState({editing: false, text: this.state.text});
        this.props.change(this.state.text);
    }

    isInputValid(text) {
        return (text.length >= (this.props.minLength || 1) && text.length <= (this.props.maxLength || 256));
    }

    keyDown(event) {
        if(event.keyCode === 13) {
            this.finishEditing();
        } else if (event.keyCode === 27) {
            this.cancelEditing();
        }
    }

    textChanged(event) {
        this.setState({
            helpText: '',
            hasError: '',
            text: event.target.value.trim()
        })
    }

    componentDidUpdate(prevProps, prevState) {
        var inputElem = React.findDOMNode(this.refs.input);
        if (this.state.editing && !prevState.editing) {
            inputElem.focus();
            SelectInputText(inputElem);
        } else if (this.state.editing && prevProps.text != this.props.text) {
            this.cancelEditing();
        }
    }

    render() {
        if(!this.state.editing) {
            return <span className={this.props.className} onClick={this.startEditing.bind(this)} style={{fontStyle: "italic"}}>{this.props.text || this.props.placeholder}</span>
        } else {
            const Element = this.props.element || 'input';
            return (
              <form className={"form-inline " + this.props.className} onSubmit={this.finishEditing.bind(this)}>
                <div className={"form-group " + this.state.hasError}>
                  <Element className={this.props.activeClassName} onKeyDown={this.keyDown.bind(this)} onBlur={this.finishEditing.bind(this)} ref="input" placeholder={this.props.placeholder} defaultValue={this.props.text} onChange={this.textChanged.bind(this)} onReturn={this.finishEditing.bind(this)} />
                  <span className="help-block">{this.state.helpText}</span>
                </div>&nbsp;
                <div className="form-group" style={{verticalAlign: "top"}}>
                  <button type="submit" className="btn btn-primary"><i className="fa fa-check"></i></button>&nbsp;
                  <button type="button" className="btn btn-default" onClick={this.cancelEditing.bind(this)}><i className="fa fa-close"></i></button>
                </div>
              </form>
            );
        }
    }
}

InlineEdit.propTypes = {
    text: React.PropTypes.string,
    className: React.PropTypes.string,
    change: React.PropTypes.func.isRequired,
    placeholder: React.PropTypes.string,
    activeClassName: React.PropTypes.string,
    minLength: React.PropTypes.number,
    maxLength: React.PropTypes.number,
    validate: React.PropTypes.func,
    element: React.PropTypes.string,
    errorText: React.PropTypes.string
};

export default InlineEdit;